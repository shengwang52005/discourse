# frozen_string_literal: true

require "monitor"

class SiteCache
  include MonitorMixin

  def initialize(max_global_size, max_size_per_site)
    mon_initialize

    raise ArgumentError.new(:max_global_size) if max_global_size < 1
    raise ArgumentError.new(:max_size_per_site) if max_size_per_site < 1

    @max_global_size = max_global_size
    @max_size_per_site = max_size_per_site
    @flattened = {}
    @nested = {}
  end

  def delete(site_id, key)
    synchronize do
      found = true
      value = @flattened.delete([site_id, key]) { found = false }

      if found
        delete_nested(site_id, key)
        value
      else
        nil
      end
    end
  end

  def set(site_id, key, value)
    synchronize do
      found = true
      @flattened.delete([site_id, key]) { found = false }

      if found
        @flattened[[site_id, key]] = value
        replace_nested(site_id, key, value)
      else
        insert_non_existent(site_id, key, value)
      end

      nil
    end
  end

  def lookup(site_id, key)
    synchronize do
      found = true
      value = @flattened.delete([site_id, key]) { found = false }

      if found
        @flattened[[site_id, key]] = value
        replace_nested(site_id, key, value)
        value
      else
        nil
      end
    end
  end

  def getset(site_id, key)
    synchronize do
      found = true
      value = @flattened.delete([site_id, key]) { found = false }

      if found
        @flattened[[site_id, key]] = value
        replace_nested(site_id, key, value)
        value
      else
        value = yield
        insert_non_existent(site_id, key, value)
        value
      end
    end
  end

  def getset_bulk(site_id, keys, key_blk, &blk)
    result = {}
    synchronize do
      hash = @nested[site_id] || {}
      missing_keys = keys.select { |key| !hash.key?(key_blk.call(key)) }

      unless missing_keys.empty?
        missing_values = blk.call(missing_keys)

        missing_keys
          .map(&key_blk)
          .zip(missing_values)
          .each { |key, value| set(site_id, key, value) }
      end

      keys.map { |key| [key, lookup(site_id, key_blk.call(key))] }.to_h
    end
  end

  def key?(site_id, key)
    synchronize { @flattened.key?([site_id, key]) }
  end

  def count
    synchronize { @flattened.size }
  end

  def clear
    synchronize do
      @flattened.clear
      @nested.clear
    end
  end

  def clear_site(site_id)
    synchronize do
      (@nested[site_id] || {}).keys.each { |key| @flattened.delete([site_id, key]) }
      @nested.delete(site_id)
      nil
    end
  end

  def clear_site_regex(site_id, regex)
    synchronize do
      site_hash = @nested[site_id] || {}
      deleted_keys = site_hash.keys.grep(regex)

      deleted_keys.each do |key|
        site_hash.delete(key)
        @flattened.delete([site_id, key])
      end

      @nested.delete(site_id) if site_hash.empty?

      nil
    end
  end

  def to_a
    synchronize do
      array = @flattened.to_a
      array.reverse!
    end
  end

  def keys
    synchronize do
      array = @flattened.keys
      array.reverse!
    end
  end

  def site_keys(site_id)
    synchronize do
      array = (@nested[site_id] || {}).keys
      array.reverse!
    end
  end

  def values
    synchronize do
      array = @flattened.values
      array.reverse!
    end
  end

  private

  def insert_non_existent(site_id, key, value)
    @flattened[[site_id, key]] = value
    site_hash = (@nested[site_id] ||= {})
    site_hash[key] = value

    while site_hash.size > @max_size_per_site
      evicted_key = site_hash.shift.first
      @flattened.delete([site_id, evicted_key])
    end

    while @flattened.size > @max_global_size
      evicted_site_id, evicted_key = @flattened.shift.first
      delete_nested(evicted_site_id, evicted_key)
    end
  end

  def replace_nested(site_id, key, value)
    site_hash = @nested[site_id]
    site_hash.delete(key)
    site_hash[key] = value
  end

  def delete_nested(site_id, key)
    site_hash = @nested[site_id]
    site_hash.delete(key)

    @nested.delete(site_id) if site_hash.empty?
  end
end
