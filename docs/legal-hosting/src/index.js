export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    const prefix = "/aussiestart";
    if (url.pathname === prefix || url.pathname === `${prefix}/`) {
      url.pathname = "/";
    } else if (url.pathname.startsWith(`${prefix}/`)) {
      url.pathname = url.pathname.slice(prefix.length);
    }
    return env.ASSETS.fetch(new Request(url, request));
  },
};
