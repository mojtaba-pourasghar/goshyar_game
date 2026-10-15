// ارسال اعلان به گوشی‌هایی که گوش‌یار را نصب کرده‌اند، از راه وب‌سرویس پوشه.
//
// گوشی‌ها اعلان را با SDK بومی پوشه می‌گیرند (android/app/build.gradle.kts؛ توکن SDK در
// android/services.properties). این‌جا فقط فرستادن است: عنوان، متن، و اگر بخواهید یک عکس.
//
// توکن وب‌سرویس (با توکن SDK فرق دارد) در voice-studio.config.json ذخیره می‌شود و در گیت نیست.
// نشانی و شکل درخواست قابل تغییرند، چون از این محیط به سرور پوشه دسترسی نبود و با سرور واقعی
// آزموده نشده‌اند. پاسخ کامل سرور در لاگ نوشته می‌شود تا اگر چیزی باید عوض شود، دیده شود.

export const PUSH_DEFAULTS = {
  apiToken: "",
  appId: "com.goshyar.app",
  endpoint: "https://api.pushe.co/v2/messaging/notifications/",
};

/** بدنه‌ی درخواست؛ جدا تا بشود بی‌شبکه آزمودش. */
export function buildPayload({ appId, title, content, image, url }) {
  const data = { title: String(title).trim(), content: String(content).trim() };
  if (image) data.image = String(image).trim();
  if (url) data.action = { action_type: "U", url: String(url).trim() };
  return { app_ids: [appId], data };
}

export function validate({ title, content, image, url }) {
  if (!String(title || "").trim()) return "عنوان خالی است";
  if (!String(content || "").trim()) return "متن خالی است";
  for (const [name, value] of [["عکس", image], ["پیوند", url]]) {
    if (value && !/^https:\/\//i.test(String(value).trim())) return `${name} باید نشانی کامل https:// باشد`;
  }
  return null;
}

export async function sendPush(settings, message, { fetchImpl = fetch } = {}) {
  if (!settings.apiToken) throw new Error("توکن وب‌سرویس پوشه داده نشده");
  const problem = validate(message);
  if (problem) throw new Error(problem);
  const payload = buildPayload({ appId: settings.appId, ...message });
  const res = await fetchImpl(settings.endpoint, {
    method: "POST",
    headers: { "Content-Type": "application/json", Authorization: `Token ${settings.apiToken}` },
    body: JSON.stringify(payload),
    signal: AbortSignal.timeout(30000),
  });
  const text = await res.text();
  return { ok: res.ok, status: res.status, body: text.slice(0, 2000), payload };
}
