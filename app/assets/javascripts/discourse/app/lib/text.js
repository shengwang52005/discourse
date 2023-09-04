import PrettyText, { buildOptions } from "pretty-text/pretty-text";
import { buildEmojiUrl, performEmojiUnescape } from "pretty-text/emoji";
import AllowLister from "pretty-text/allow-lister";
import { Promise } from "rsvp";
import Session from "discourse/models/session";
import { formatUsername } from "discourse/lib/utilities";
import { getURLWithCDN } from "discourse-common/lib/get-url";
import { helperContext } from "discourse-common/lib/helpers";
import { htmlSafe } from "@ember/template";
import loadScript from "discourse/lib/load-script";
import { sanitize as textSanitize } from "pretty-text/sanitizer";
import { mentionRegex } from "pretty-text/mentions";

function getOpts(opts) {
  let context = helperContext();

  opts = Object.assign(
    {
      getURL: getURLWithCDN,
      currentUser: context.currentUser,
      censoredRegexp: context.site.censored_regexp,
      customEmojiTranslation: context.site.custom_emoji_translation,
      emojiDenyList: context.site.denied_emojis,
      siteSettings: context.siteSettings,
      formatUsername,
      watchedWordsReplace: context.site.watched_words_replace,
      watchedWordsLink: context.site.watched_words_link,
      additionalOptions: context.site.markdown_additional_options,
    },
    opts
  );

  return buildOptions(opts);
}

// Use this to easily create a pretty text instance with proper options
export function cook(text, options) {
  return htmlSafe(createPrettyText(options).cook(text));
}

// everything should eventually move to async API and this should be renamed
// cook
export function cookAsync(text, options) {
  return loadMarkdownIt().then(() => cook(text, options));
}

// Warm up pretty text with a set of options and return a function
// which can be used to cook without rebuilding pretty-text every time
export function generateCookFunction(options) {
  return loadMarkdownIt().then(() => {
    const prettyText = createPrettyText(options);
    return (text) => prettyText.cook(text);
  });
}

export function generateLinkifyFunction(options) {
  return loadMarkdownIt().then(() => {
    const prettyText = createPrettyText(options);
    return prettyText.opts.engine.linkify;
  });
}

export function sanitize(text, options) {
  return textSanitize(text, new AllowLister(options));
}

export function sanitizeAsync(text, options) {
  return loadMarkdownIt().then(() => {
    return createPrettyText(options).sanitize(text);
  });
}

export function parseAsync(md, options = {}, env = {}) {
  return loadMarkdownIt().then(() => {
    return createPrettyText(options).opts.engine.parse(md, env);
  });
}

// fixme andrei write tests for this method
export async function parseMentions(
  markdown,
  unicodeUsernamesEnabled,
  options
) {
  console.log("markdown", markdown);

  await loadMarkdownIt();
  const prettyText = createPrettyText(options);
  const tokens = prettyText.parseMarkdownTokens(markdown);
  console.log("Parsed tokens", tokens);

  let mentions = [];

  for (const token of tokens) {
    if (!token.content) {
      continue;
    }

    if (token.type === "code_inline" && token.tag === "code") {
      continue;
    }

    const regExp = mentionRegex(unicodeUsernamesEnabled, true);
    const matches = token.content.matchAll(regExp);
    for (const match of matches) {
      console.log("match", match);
      const mention = match[1] || match[2]; // fixme andrei why do we do it like this?
      if (mention) {
        mentions.push(mention);
      }
    }
  }

  console.log("mentions", mentions);

  return [...new Set(mentions)];
}

function loadMarkdownIt() {
  return new Promise((resolve) => {
    let markdownItURL = Session.currentProp("markdownItURL");
    if (markdownItURL) {
      loadScript(markdownItURL)
        .then(() => resolve())
        .catch((e) => {
          // eslint-disable-next-line no-console
          console.error(e);
        });
    } else {
      resolve();
    }
  });
}

function createPrettyText(options) {
  return new PrettyText(getOpts(options));
}

function emojiOptions() {
  let siteSettings = helperContext().siteSettings;
  let context = helperContext();
  if (!siteSettings.enable_emoji) {
    return;
  }

  return {
    getURL: (url) => getURLWithCDN(url),
    emojiSet: siteSettings.emoji_set,
    enableEmojiShortcuts: siteSettings.enable_emoji_shortcuts,
    inlineEmoji: siteSettings.enable_inline_emoji_translation,
    emojiDenyList: context.site.denied_emojis,
    emojiCDNUrl: siteSettings.external_emoji_url,
  };
}

export function emojiUnescape(string, options) {
  const opts = emojiOptions();
  if (opts) {
    return performEmojiUnescape(string, Object.assign(opts, options || {}));
  } else {
    return string;
  }
}

export function emojiUrlFor(code) {
  const opts = emojiOptions();
  if (opts) {
    return buildEmojiUrl(code, opts);
  }
}

function encode(str) {
  return str.replaceAll("<", "&lt;").replaceAll(">", "&gt;");
}

function traverse(element, callback) {
  if (callback(element)) {
    element.childNodes.forEach((child) => traverse(child, callback));
  }
}

export function excerpt(cooked, length) {
  let result = "";
  let resultLength = 0;

  const div = document.createElement("div");
  div.innerHTML = cooked;
  traverse(div, (element) => {
    if (resultLength >= length) {
      return;
    }

    if (element.nodeType === Node.TEXT_NODE) {
      if (resultLength + element.textContent.length > length) {
        const text = element.textContent.slice(0, length - resultLength);
        result += encode(text);
        result += "&hellip;";
        resultLength += text.length;
      } else {
        result += encode(element.textContent);
        resultLength += element.textContent.length;
      }
    } else if (element.tagName === "A") {
      result += element.outerHTML;
      resultLength += element.innerText.length;
    } else if (element.tagName === "IMG") {
      if (element.classList.contains("emoji")) {
        result += element.outerHTML;
      } else {
        result += "[image]";
        resultLength += "[image]".length;
      }
    } else {
      return true;
    }
  });

  return result;
}
