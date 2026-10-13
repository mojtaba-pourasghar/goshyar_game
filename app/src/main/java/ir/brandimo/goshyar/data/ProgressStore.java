package ir.brandimo.goshyar.data;

import android.content.Context;
import android.content.SharedPreferences;

import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

/**
 * پیشرفت کودک را در SharedPreferences نگه می‌دارد تا بین اجراهای برنامه از بین نرود:
 * امتیاز، مراحل کامل‌شده، بهترین زنجیره پاسخ درست و مدال‌های باز شده.
 */
public class ProgressStore {

    private static final String PREFS = "goshyar_progress";
    private static final String K_NAME = "child_name";
    private static final String K_POINTS = "total_points";
    private static final String K_DONE = "completed_levels";   // "mode:n"
    private static final String K_BADGES = "unlocked_badges";
    private static final String K_STREAK = "best_streak";

    private static ProgressStore instance;

    private final SharedPreferences prefs;
    private final GameContent content;
    private int currentStreak = 0;

    private ProgressStore(Context ctx) {
        this.prefs = ctx.getApplicationContext().getSharedPreferences(PREFS, Context.MODE_PRIVATE);
        this.content = GameContent.get(ctx);
    }

    public static synchronized ProgressStore get(Context ctx) {
        if (instance == null) instance = new ProgressStore(ctx);
        return instance;
    }

    // ---- خواندن ----

    public String childName() { return prefs.getString(K_NAME, "آرین"); }
    public void setChildName(String name) { prefs.edit().putString(K_NAME, name).apply(); }

    public int totalPoints() { return prefs.getInt(K_POINTS, 0); }
    public int bestStreak() { return prefs.getInt(K_STREAK, 0); }
    public int currentStreak() { return currentStreak; }

    public Set<String> completedLevels() {
        return new HashSet<>(prefs.getStringSet(K_DONE, new HashSet<>()));
    }

    public int completedCount() { return completedLevels().size(); }

    public Set<String> unlockedBadges() {
        return new HashSet<>(prefs.getStringSet(K_BADGES, new HashSet<>()));
    }

    public int medalsCount() { return unlockedBadges().size(); }

    public int level() { return 1 + totalPoints() / Math.max(1, content.pointsPerLevel()); }

    public boolean isLevelDone(String modeId, int n) {
        return completedLevels().contains(key(modeId, n));
    }

    /** چند مرحله از این حالت کامل شده است. */
    public int completedInMode(String modeId) {
        int n = 0;
        for (String k : completedLevels()) if (k.startsWith(modeId + ":")) n++;
        return n;
    }

    /** اولین مرحله کامل‌نشده این حالت؛ اگر همه تمام شده‌اند، صفر. */
    public int firstUnfinished(String modeId) {
        GameMode m = content.mode(modeId);
        if (m == null) return 0;
        for (int i = 0; i < m.levelCount(); i++) {
            if (!isLevelDone(modeId, m.level(i).number)) return i;
        }
        return 0;
    }

    private int completedInCategory(String categoryId) {
        int n = 0;
        for (GameMode m : content.allModes()) {
            for (GameLevel l : m.levels) {
                if (isLevelDone(m.id, l.number) && categoryId.equals(content.levelCategory(l))) n++;
            }
        }
        return n;
    }

    // ---- نوشتن ----

    /** پاسخ درست: امتیاز می‌دهد، مرحله را کامل علامت می‌زند و مدال‌های تازه را برمی‌گرداند. */
    public List<Achievement> onCorrect(String modeId, int levelNumber, boolean firstTry) {
        int pts = content.correctPoints() + (firstTry ? content.firstTryBonus() : 0);
        Set<String> done = completedLevels();
        done.add(key(modeId, levelNumber));

        currentStreak++;
        int best = Math.max(bestStreak(), currentStreak);

        prefs.edit()
                .putInt(K_POINTS, totalPoints() + pts)
                .putStringSet(K_DONE, done)
                .putInt(K_STREAK, best)
                .apply();

        return refreshBadges();
    }

    /** پاسخ غلط: فقط زنجیره را صفر می‌کند. */
    public void onWrong() { currentStreak = 0; }

    /** امتیازی که برای یک پاسخ درست داده می‌شود. */
    public int pointsForCorrect(boolean firstTry) {
        return content.correctPoints() + (firstTry ? content.firstTryBonus() : 0);
    }

    /** قانون‌های دستاوردها را بررسی و مدال‌های تازه باز شده را برمی‌گرداند. */
    public List<Achievement> refreshBadges() {
        Set<String> have = unlockedBadges();
        List<Achievement> fresh = new ArrayList<>();
        for (Achievement a : content.allAchievements()) {
            if (have.contains(a.id)) continue;
            if (ruleSatisfied(a.rule)) {
                have.add(a.id);
                fresh.add(a);
            }
        }
        if (!fresh.isEmpty()) prefs.edit().putStringSet(K_BADGES, have).apply();
        return fresh;
    }

    public boolean isBadgeUnlocked(String badgeId) { return unlockedBadges().contains(badgeId); }

    /** قانون‌های پشتیبانی‌شده: levels>=N ، streak>=N ، cat:ID>=N ، mode:ID>=N */
    private boolean ruleSatisfied(String rule) {
        if (rule == null) return false;
        int at = rule.indexOf(">=");
        if (at < 0) return false;
        String left = rule.substring(0, at).trim();
        int need;
        try {
            need = Integer.parseInt(rule.substring(at + 2).trim());
        } catch (NumberFormatException e) {
            return false;
        }
        if ("levels".equals(left)) return completedCount() >= need;
        if ("streak".equals(left)) return bestStreak() >= need;
        if (left.startsWith("cat:")) return completedInCategory(left.substring(4)) >= need;
        if (left.startsWith("mode:")) return completedInMode(left.substring(5)) >= need;
        return false;
    }

    public void reset() {
        currentStreak = 0;
        prefs.edit().remove(K_POINTS).remove(K_DONE).remove(K_BADGES).remove(K_STREAK).apply();
    }

    private static String key(String modeId, int n) { return modeId + ":" + n; }
}
