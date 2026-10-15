import React, { useState } from "react";

// ارسال اعلان به همه‌ی گوشی‌هایی که گوش‌یار را نصب کرده‌اند (وب‌سرویس پوشه؛ server/push.js).

async function call(path, body) {
  const res = await fetch("/api" + path, {
    method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify(body),
  });
  const text = await res.text();
  const data = text ? JSON.parse(text) : {};
  if (!res.ok && !data.status) throw new Error(data.error || `HTTP ${res.status}`);
  return data;
}

export default function PushPanel({ config, onSaved }) {
  const push = config.push || {};
  const [settings, setSettings] = useState({ appId: push.appId || "", endpoint: push.endpoint || "", apiToken: "" });
  const [msg, setMsg] = useState({ title: "", content: "", image: "", url: "" });
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState("");
  const [result, setResult] = useState(null);
  const [imageOk, setImageOk] = useState(true);

  const save = async () => {
    setBusy(true);
    try {
      const body = { push: { appId: settings.appId, endpoint: settings.endpoint,
                             ...(settings.apiToken ? { apiToken: settings.apiToken } : {}) } };
      onSaved(await call("/config", body));
      setSettings({ ...settings, apiToken: "" });
      setError("");
    } catch (err) { setError(err.message); }
    setBusy(false);
  };

  const send = async () => {
    if (!window.confirm(`این اعلان برای همه‌ی کاربران «${push.appId}» فرستاده شود؟\n\n${msg.title}\n${msg.content}`)) return;
    setBusy(true);
    try {
      setResult(await call("/push/send", msg));
      setError("");
    } catch (err) { setError(err.message); setResult(null); }
    setBusy(false);
  };

  const field = (key, label, extra = {}) => (
    <div>
      <label>{label}</label>
      <input type="text" value={msg[key]} onChange={(e) => setMsg({ ...msg, [key]: e.target.value })} {...extra} />
    </div>
  );

  return (
    <>
      <div className="card">
        <h2>🔔 ارسال اعلان <span className="hint">به همه‌ی گوشی‌هایی که گوش‌یار را نصب کرده‌اند</span></h2>
        {error && <div className="err">{error}</div>}
        <div className="grid">
          {field("title", "عنوان", { maxLength: 60, placeholder: "مثلاً: مرحله‌های تازه رسید!" })}
          {field("image", "عکس (اختیاری) — نشانی https", { dir: "ltr", placeholder: "https://…/banner.jpg" })}
        </div>
        <div style={{ marginTop: 12 }}>
          <label>متن</label>
          <textarea rows={3} style={{ width: "100%" }} maxLength={240} value={msg.content}
                    placeholder="مثلاً: گوش‌یار با صداهای تازه‌ی جنگل منتظر توست."
                    onChange={(e) => setMsg({ ...msg, content: e.target.value })} />
        </div>
        <div className="grid" style={{ marginTop: 12 }}>
          {field("url", "پیوند هنگام لمس (اختیاری)", { dir: "ltr", placeholder: "https://cafebazaar.ir/app/com.goshyar.app" })}
        </div>

        {(msg.title || msg.content || msg.image) && (
          <div className="push-preview">
            <div className="push-head">🐻 گوش‌یار · همین حالا</div>
            <b>{msg.title || "عنوان"}</b>
            <div>{msg.content || "متن"}</div>
            {msg.image && (imageOk
              ? <img src={msg.image} alt="" onError={() => setImageOk(false)} onLoad={() => setImageOk(true)} />
              : <div className="note">عکس باز نشد — نشانی را بررسی کنید</div>)}
          </div>
        )}

        <div className="row" style={{ marginTop: 12 }}>
          <button className="go" disabled={busy || !push.apiTokenSet || !msg.title.trim() || !msg.content.trim()}
                  onClick={send}>
            {busy ? "در حال ارسال…" : "ارسال اعلان"}
          </button>
          {!push.apiTokenSet && <span className="note">اول توکن وب‌سرویس پوشه را پایین ذخیره کنید.</span>}
        </div>

        {result && (
          <p className={result.ok ? "note" : "err"} style={{ direction: "ltr", textAlign: "left", whiteSpace: "pre-wrap" }}>
            HTTP {result.status} — {result.body}
          </p>
        )}
        <p className="note">
          عکس باید روی اینترنت با نشانی https در دسترس باشد (اعلان‌ها فایل همراه ندارند؛ گوشی عکس را از همان
          نشانی می‌گیرد). اندازه‌ی مناسب: افقی ۲:۱، مثلاً ۱۰۲۴×۵۱۲.
        </p>
      </div>

      <div className="card">
        <h2>⚙️ تنظیمات پوشه <span className="hint">{push.apiTokenSet ? "✓ توکن ذخیره شده" : "توکن داده نشده"}</span></h2>
        <div className="grid">
          <div>
            <label>توکن وب‌سرویس (کنسول پوشه ← تنظیمات ← API)</label>
            <input type="password" value={settings.apiToken} placeholder={push.apiTokenSet ? "ذخیره شده — برای تغییر بنویسید" : ""}
                   onChange={(e) => setSettings({ ...settings, apiToken: e.target.value })} />
          </div>
          <div>
            <label>شناسه‌ی برنامه در پوشه</label>
            <input type="text" dir="ltr" value={settings.appId} onChange={(e) => setSettings({ ...settings, appId: e.target.value })} />
          </div>
          <div>
            <label>نشانی وب‌سرویس</label>
            <input type="text" dir="ltr" value={settings.endpoint} onChange={(e) => setSettings({ ...settings, endpoint: e.target.value })} />
          </div>
        </div>
        <div className="row" style={{ marginTop: 12 }}>
          <button className="ghost" disabled={busy} onClick={save}>ذخیره‌ی تنظیمات پوشه</button>
        </div>
        <p className="note">
          توکن در <code>{config.configFile}</code> می‌ماند و در گیت نیست. این توکن با «توکن SDK» که در
          <code> android/services.properties</code> (<code>pushe.token</code>) می‌گذارید فرق دارد.
          اولین بار با یک گوشی آزمایشی امتحان کنید: شکل درخواست با سرور واقعی پوشه آزموده نشده و پاسخ کامل
          سرور همین‌جا و در لاگ نشان داده می‌شود.
        </p>
      </div>
    </>
  );
}
