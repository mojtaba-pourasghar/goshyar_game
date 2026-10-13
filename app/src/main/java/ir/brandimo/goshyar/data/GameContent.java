package ir.brandimo.goshyar.data;

import android.content.Context;
import android.content.res.Resources;
import android.util.Log;

import org.json.JSONArray;
import org.json.JSONObject;

import java.io.ByteArrayOutputStream;
import java.io.InputStream;
import java.util.ArrayList;
import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * کل محتوای بازی را یک بار از assets/levels.json می‌خواند و در حافظه نگه می‌دارد:
 * دسته‌بندی‌ها، بانک صداها، مکان‌ها، چهار حالت بازی با همه مراحلشان و دستاوردها.
 */
public final class GameContent {

    private static final String TAG = "GameContent";
    private static final String ASSET = "levels.json";

    private static GameContent instance;

    private final Map<String, GameCategory> categories = new LinkedHashMap<>();
    private final Map<String, SoundItem> sounds = new LinkedHashMap<>();
    private final Map<String, PlaceItem> places = new LinkedHashMap<>();
    private final Map<String, GameMode> modes = new LinkedHashMap<>();
    private final List<Achievement> achievements = new ArrayList<>();

    private int correctPoints = 20;
    private int firstTryBonus = 5;
    private int pointsPerLevel = 500;
    private boolean loaded = false;

    private GameContent() {}

    public static synchronized GameContent get(Context context) {
        if (instance == null) {
            instance = new GameContent();
            instance.load(context.getApplicationContext());
        }
        return instance;
    }

    private void load(Context context) {
        try {
            JSONObject root = new JSONObject(readAsset(context, ASSET));

            JSONArray cats = root.getJSONArray("categories");
            for (int i = 0; i < cats.length(); i++) {
                JSONObject c = cats.getJSONObject(i);
                categories.put(c.getString("id"), new GameCategory(
                        c.getString("id"), c.getString("title"),
                        c.optString("icon"), c.optString("color")));
            }

            JSONArray snds = root.getJSONArray("sounds");
            for (int i = 0; i < snds.length(); i++) {
                JSONObject s = snds.getJSONObject(i);
                sounds.put(s.getString("id"), new SoundItem(
                        s.getString("id"), s.getString("title"), s.getString("category"),
                        s.optString("image"), s.optString("audio")));
            }

            JSONArray plcs = root.getJSONArray("places");
            for (int i = 0; i < plcs.length(); i++) {
                JSONObject p = plcs.getJSONObject(i);
                places.put(p.getString("id"), new PlaceItem(
                        p.getString("id"), p.getString("title"), p.optString("image")));
            }

            JSONArray mds = root.getJSONArray("modes");
            for (int i = 0; i < mds.length(); i++) {
                JSONObject m = mds.getJSONObject(i);
                GameMode mode = new GameMode(m.getString("id"), m.getString("title"),
                        m.optString("instruction"), m.optString("icon"), m.optString("color"));
                JSONArray lvls = m.getJSONArray("levels");
                for (int j = 0; j < lvls.length(); j++) {
                    mode.levels.add(parseLevel(mode.id, lvls.getJSONObject(j)));
                }
                modes.put(mode.id, mode);
            }

            JSONArray achs = root.optJSONArray("achievements");
            if (achs != null) {
                for (int i = 0; i < achs.length(); i++) {
                    JSONObject a = achs.getJSONObject(i);
                    achievements.add(new Achievement(a.getString("id"), a.getString("title"),
                            a.optString("desc"), a.optString("icon"), a.optString("rule")));
                }
            }

            JSONObject sc = root.optJSONObject("scoring");
            if (sc != null) {
                correctPoints = sc.optInt("correctPoints", correctPoints);
                firstTryBonus = sc.optInt("firstTryBonus", firstTryBonus);
                pointsPerLevel = sc.optInt("pointsPerLevel", pointsPerLevel);
            }

            loaded = true;
            Log.i(TAG, "محتوا بارگذاری شد: " + sounds.size() + " صدا، " + totalLevels() + " مرحله");
        } catch (Exception e) {
            Log.e(TAG, "خواندن " + ASSET + " شکست خورد", e);
        }
    }

    private GameLevel parseLevel(String modeId, JSONObject l) {
        GameLevel lvl = new GameLevel(modeId, l.optInt("n"), l.optString("voice"));
        lvl.soundId = l.optString("sound", null);
        lvl.answerId = l.optString("answer", null);

        JSONArray opts = l.optJSONArray("options");
        if (opts != null) {
            for (int i = 0; i < opts.length(); i++) {
                if (GameMode.AUDIO_MISSION.equals(modeId)) {
                    lvl.countOptions.add(opts.optInt(i));
                } else {
                    lvl.options.add(opts.optString(i));
                }
            }
        }
        // در «این صدا مال کیه؟» گزینه درست همان صدای پخش‌شده است.
        if (lvl.answerId == null && lvl.soundId != null) lvl.answerId = lvl.soundId;

        JSONArray seq = l.optJSONArray("sequence");
        if (seq != null) for (int i = 0; i < seq.length(); i++) lvl.sequence.add(seq.optString(i));

        lvl.sceneTitle = l.optString("scene", null);
        lvl.backgroundName = l.optString("background", null);
        JSONArray lay = l.optJSONArray("layers");
        if (lay != null) for (int i = 0; i < lay.length(); i++) lvl.layers.add(lay.optString(i));
        lvl.answerCount = l.optInt("answer", 0);
        return lvl;
    }

    private static String readAsset(Context ctx, String name) throws Exception {
        try (InputStream in = ctx.getAssets().open(name)) {
            ByteArrayOutputStream out = new ByteArrayOutputStream();
            byte[] buf = new byte[8192];
            int n;
            while ((n = in.read(buf)) > 0) out.write(buf, 0, n);
            return out.toString("UTF-8");
        }
    }

    // ---- دسترسی ----

    public boolean isLoaded() { return loaded; }
    public GameMode mode(String id) { return modes.get(id); }
    public List<GameMode> allModes() { return new ArrayList<>(modes.values()); }
    public SoundItem sound(String id) { return sounds.get(id); }
    public PlaceItem place(String id) { return places.get(id); }
    public GameCategory category(String id) { return categories.get(id); }
    public List<GameCategory> allCategories() { return new ArrayList<>(categories.values()); }
    public List<Achievement> allAchievements() { return Collections.unmodifiableList(achievements); }

    public int correctPoints() { return correctPoints; }
    public int firstTryBonus() { return firstTryBonus; }
    public int pointsPerLevel() { return pointsPerLevel; }

    public int totalLevels() {
        int n = 0;
        for (GameMode m : modes.values()) n += m.levelCount();
        return n;
    }

    /** عنوان فارسی یک گزینه، چه مکان باشد چه صدا. */
    public String optionTitle(String modeId, String optionId) {
        if (GameMode.FIND_SOURCE.equals(modeId)) {
            PlaceItem p = places.get(optionId);
            if (p != null) return p.title;
        }
        SoundItem s = sounds.get(optionId);
        return s != null ? s.title : optionId;
    }

    /** نام تصویر یک گزینه. */
    public String optionImage(String modeId, String optionId) {
        if (GameMode.FIND_SOURCE.equals(modeId)) {
            PlaceItem p = places.get(optionId);
            if (p != null) return p.imageName;
        }
        SoundItem s = sounds.get(optionId);
        return s != null ? s.imageName : null;
    }

    /** دسته‌بندی یک مرحله، برای شمارش دستاوردهای دسته‌ای. */
    public String levelCategory(GameLevel level) {
        String sid = level.soundId;
        if (sid == null && !level.sequence.isEmpty()) sid = level.sequence.get(0);
        if (sid == null && !level.layers.isEmpty()) sid = level.layers.get(0);
        SoundItem s = sid != null ? sounds.get(sid) : null;
        return s != null ? s.category : "";
    }

    /** نام drawable را به شناسه منبع تبدیل می‌کند؛ اگر نبود، fallback برمی‌گرداند. */
    public static int drawableId(Context ctx, String name, int fallback) {
        if (name == null || name.isEmpty()) return fallback;
        Resources res = ctx.getResources();
        int id = res.getIdentifier(name, "drawable", ctx.getPackageName());
        return id != 0 ? id : fallback;
    }
}
