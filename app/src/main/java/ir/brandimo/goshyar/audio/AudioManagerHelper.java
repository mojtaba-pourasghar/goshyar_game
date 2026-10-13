package ir.brandimo.goshyar.audio;

import android.content.Context;
import android.content.SharedPreferences;
import android.content.res.AssetFileDescriptor;
import android.media.AudioAttributes;
import android.media.AudioFormat;
import android.media.AudioManager;
import android.media.AudioTrack;
import android.media.MediaPlayer;
import android.os.Build;
import android.os.Handler;
import android.os.Looper;
import android.util.Log;

import java.io.IOException;
import java.util.ArrayList;
import java.util.List;

/**
 * تمام صدای بازی از اینجا پخش می‌شود:
 *  - افکت‌ها و صداهای بازی از assets/sfx/
 *  - گوینده فارسی از assets/voice/   (ساخته‌شده با tools/generate_voice.py)
 *  - اگر فایلی موجود نبود، به تُن ساده برمی‌گردد تا بازی قفل نشود.
 */
public class AudioManagerHelper {

    private static final String TAG = "AudioHelper";
    private static final String PREFS = "goshyar_audio";
    private static final String K_MUSIC = "music_enabled";
    private static final String K_SFX = "sfx_enabled";
    private static final String K_VOICE = "voice_enabled";

    private static AudioManagerHelper instance;

    private Context context;
    private SharedPreferences prefs;
    private MediaPlayer sfxPlayer;
    private MediaPlayer voicePlayer;
    private MediaPlayer bgPlayer;
    private final Handler main = new Handler(Looper.getMainLooper());
    private final List<Runnable> pending = new ArrayList<>();

    public interface OnDone { void onDone(); }

    private AudioManagerHelper() {}

    public static synchronized AudioManagerHelper getInstance() {
        if (instance == null) instance = new AudioManagerHelper();
        return instance;
    }

    public void init(Context ctx) {
        this.context = ctx.getApplicationContext();
        this.prefs = this.context.getSharedPreferences(PREFS, Context.MODE_PRIVATE);
    }

    // ---- تنظیمات ----

    public boolean isMusicEnabled() { return prefs == null || prefs.getBoolean(K_MUSIC, true); }
    public boolean isSfxEnabled()   { return prefs == null || prefs.getBoolean(K_SFX, true); }
    public boolean isVoiceEnabled() { return prefs == null || prefs.getBoolean(K_VOICE, true); }

    public void setMusicEnabled(boolean on) {
        if (prefs != null) prefs.edit().putBoolean(K_MUSIC, on).apply();
        if (!on) stopBackgroundMusic();
    }

    public void setSfxEnabled(boolean on) {
        if (prefs != null) prefs.edit().putBoolean(K_SFX, on).apply();
    }

    public void setVoiceEnabled(boolean on) {
        if (prefs != null) prefs.edit().putBoolean(K_VOICE, on).apply();
    }

    // ---- پخش صدای بازی ----

    /** یک فایل از assets پخش می‌کند. اگر نبود، یک تُن جایگزین می‌نوازد. */
    public void playSfx(String assetPath, OnDone onDone) {
        if (!isSfxEnabled()) { fire(onDone); return; }
        if (!playAsset(assetPath, true, onDone)) {
            // فایل صوتی هنوز اضافه نشده: تُن جایگزین تا بازی قابل اجرا بماند
            playTone(440, 400);
            main.postDelayed(() -> fire(onDone), 450);
        }
    }

    public void playSfx(String assetPath) { playSfx(assetPath, null); }

    /** چند صدا را پشت سر هم با فاصله پخش می‌کند (برای بازی «ترتیب صداها»). */
    public void playSequence(List<String> assetPaths, long gapMs, OnDone onAllDone) {
        cancelPending();
        playSequenceFrom(assetPaths, 0, gapMs, onAllDone);
    }

    private void playSequenceFrom(List<String> paths, int i, long gapMs, OnDone onAllDone) {
        if (i >= paths.size()) { fire(onAllDone); return; }
        playSfx(paths.get(i), () -> {
            Runnable next = () -> playSequenceFrom(paths, i + 1, gapMs, onAllDone);
            pending.add(next);
            main.postDelayed(next, gapMs);
        });
    }

    /** چند صدا را با هم (لایه‌لایه) پخش می‌کند — برای «مأموریت شنیداری». */
    public void playLayered(List<String> assetPaths) {
        if (!isSfxEnabled()) return;
        cancelPending();
        for (int i = 0; i < assetPaths.size(); i++) {
            final String path = assetPaths.get(i);
            Runnable r = () -> playOneShot(path);
            pending.add(r);
            main.postDelayed(r, i * 700L);
        }
    }

    // ---- گوینده ----

    /** جمله گوینده را پخش می‌کند. voiceId مثل "v_intro_hello". */
    public void playVoice(String voiceId, OnDone onDone) {
        if (voiceId == null || voiceId.isEmpty() || !isVoiceEnabled()) { fire(onDone); return; }
        String path = "voice/" + voiceId + ".mp3";
        if (!exists(path)) {
            Log.d(TAG, "فایل گوینده نیست: " + path + " — tools/generate_voice.py را اجرا کنید");
            fire(onDone);
            return;
        }
        releaseVoice();
        try {
            voicePlayer = buildPlayer(path);
            voicePlayer.setOnCompletionListener(mp -> { releaseVoice(); fire(onDone); });
            voicePlayer.start();
        } catch (Exception e) {
            Log.w(TAG, "پخش گوینده شکست خورد: " + path, e);
            releaseVoice();
            fire(onDone);
        }
    }

    public void playVoice(String voiceId) { playVoice(voiceId, null); }

    public void stopVoice() { releaseVoice(); }

    // ---- موسیقی پس‌زمینه ----

    public void startBackgroundMusic(String assetPath) {
        if (!isMusicEnabled() || !exists(assetPath)) return;
        stopBackgroundMusic();
        try {
            bgPlayer = buildPlayer(assetPath);
            bgPlayer.setLooping(true);
            bgPlayer.setVolume(0.25f, 0.25f);
            bgPlayer.start();
        } catch (Exception e) {
            Log.w(TAG, "موسیقی پس‌زمینه پخش نشد", e);
        }
    }

    public void stopBackgroundMusic() {
        if (bgPlayer != null) {
            try { bgPlayer.stop(); } catch (IllegalStateException ignored) {}
            bgPlayer.release();
            bgPlayer = null;
        }
    }

    // ---- صداهای بازخورد ----

    public void playSuccessSound() {
        if (exists("sfx/ui_success.mp3")) { playOneShot("sfx/ui_success.mp3"); return; }
        playTone(523.25, 150);                                        // C5
        main.postDelayed(() -> playTone(659.25, 250), 150);           // E5
    }

    public void playFailSound() {
        if (exists("sfx/ui_fail.mp3")) { playOneShot("sfx/ui_fail.mp3"); return; }
        playTone(300.0, 200);
        main.postDelayed(() -> playTone(220.0, 300), 200);
    }

    public void playTapSound() {
        if (exists("sfx/ui_tap.mp3")) { playOneShot("sfx/ui_tap.mp3"); return; }
        playTone(880.0, 70);
    }

    // ---- داخلی ----

    public boolean exists(String assetPath) {
        if (context == null || assetPath == null || assetPath.isEmpty()) return false;
        try (AssetFileDescriptor afd = context.getAssets().openFd(assetPath)) {
            return afd.getLength() > 0;
        } catch (IOException e) {
            return false;
        }
    }

    private MediaPlayer buildPlayer(String assetPath) throws IOException {
        MediaPlayer mp = new MediaPlayer();
        try (AssetFileDescriptor afd = context.getAssets().openFd(assetPath)) {
            mp.setDataSource(afd.getFileDescriptor(), afd.getStartOffset(), afd.getLength());
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            mp.setAudioAttributes(new AudioAttributes.Builder()
                    .setUsage(AudioAttributes.USAGE_GAME)
                    .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                    .build());
        } else {
            mp.setAudioStreamType(AudioManager.STREAM_MUSIC);
        }
        mp.prepare();
        return mp;
    }

    private boolean playAsset(String assetPath, boolean asSfx, OnDone onDone) {
        if (!exists(assetPath)) return false;
        try {
            if (asSfx) releaseSfx();
            MediaPlayer mp = buildPlayer(assetPath);
            mp.setOnCompletionListener(p -> {
                p.release();
                if (asSfx && sfxPlayer == p) sfxPlayer = null;
                fire(onDone);
            });
            if (asSfx) sfxPlayer = mp;
            mp.start();
            return true;
        } catch (Exception e) {
            Log.w(TAG, "پخش شکست خورد: " + assetPath, e);
            return false;
        }
    }

    /** پخش بدون قطع کردن صدای قبلی — برای لایه‌های همزمان. */
    private void playOneShot(String assetPath) {
        if (!exists(assetPath)) { playTone(440, 300); return; }
        try {
            MediaPlayer mp = buildPlayer(assetPath);
            mp.setOnCompletionListener(MediaPlayer::release);
            mp.start();
        } catch (Exception e) {
            Log.w(TAG, "پخش همزمان شکست خورد: " + assetPath, e);
        }
    }

    /**
     * تُن سینوسی جایگزین، وقتی فایل صوتی موجود نیست.
     * AudioTrack.Builder از API 23 است، پس روی اندروید ۵ از سازنده قدیمی استفاده می‌شود.
     */
    public void playTone(double frequencyHz, int durationMs) {
        if (!isSfxEnabled()) return;

        new Thread(() -> {
            AudioTrack track = null;
            try {
                final int sampleRate = 44100;
                int numSamples = (int) ((long) sampleRate * durationMs / 1000);
                byte[] pcm = new byte[2 * numSamples];

                // پاکت ملایم تا صدا در ابتدا و انتها «کلیک» ندهد
                int fade = Math.min(numSamples / 8, sampleRate / 100);
                for (int i = 0; i < numSamples; i++) {
                    double v = Math.sin(2 * Math.PI * frequencyHz * i / sampleRate);
                    double gain = 1.0;
                    if (i < fade) gain = i / (double) fade;
                    else if (i > numSamples - fade) gain = (numSamples - i) / (double) fade;
                    short s = (short) (v * gain * 32767);
                    pcm[2 * i] = (byte) (s & 0x00ff);
                    pcm[2 * i + 1] = (byte) ((s & 0xff00) >> 8);
                }

                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    track = new AudioTrack.Builder()
                            .setAudioAttributes(new AudioAttributes.Builder()
                                    .setUsage(AudioAttributes.USAGE_GAME)
                                    .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                                    .build())
                            .setAudioFormat(new AudioFormat.Builder()
                                    .setEncoding(AudioFormat.ENCODING_PCM_16BIT)
                                    .setSampleRate(sampleRate)
                                    .setChannelMask(AudioFormat.CHANNEL_OUT_MONO)
                                    .build())
                            .setBufferSizeInBytes(pcm.length)
                            .setTransferMode(AudioTrack.MODE_STATIC)
                            .build();
                } else {
                    @SuppressWarnings("deprecation")
                    AudioTrack legacy = new AudioTrack(AudioManager.STREAM_MUSIC, sampleRate,
                            AudioFormat.CHANNEL_OUT_MONO, AudioFormat.ENCODING_PCM_16BIT,
                            pcm.length, AudioTrack.MODE_STATIC);
                    track = legacy;
                }

                track.write(pcm, 0, pcm.length);
                track.play();

                final AudioTrack finalTrack = track;
                main.postDelayed(() -> {
                    try { finalTrack.stop(); } catch (IllegalStateException ignored) {}
                    finalTrack.release();
                }, durationMs + 120L);
            } catch (Exception e) {
                Log.w(TAG, "تولید تُن شکست خورد", e);
                if (track != null) track.release();
            }
        }).start();
    }

    /** همه پخش‌های در جریان و زمان‌بندی‌شده را متوقف می‌کند. */
    public void stopAll() {
        cancelPending();
        releaseSfx();
        releaseVoice();
    }

    private void cancelPending() {
        for (Runnable r : pending) main.removeCallbacks(r);
        pending.clear();
    }

    private void releaseSfx() {
        if (sfxPlayer != null) {
            try { sfxPlayer.stop(); } catch (IllegalStateException ignored) {}
            sfxPlayer.release();
            sfxPlayer = null;
        }
    }

    private void releaseVoice() {
        if (voicePlayer != null) {
            try { voicePlayer.stop(); } catch (IllegalStateException ignored) {}
            voicePlayer.release();
            voicePlayer = null;
        }
    }

    private void fire(OnDone cb) { if (cb != null) main.post(cb::onDone); }
}
