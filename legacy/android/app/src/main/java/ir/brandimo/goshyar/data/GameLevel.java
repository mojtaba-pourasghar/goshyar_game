package ir.brandimo.goshyar.data;

import java.util.ArrayList;
import java.util.List;

/** یک مرحله از هر کدام از چهار حالت بازی. فیلدهای بی‌ربط به آن حالت خالی می‌مانند. */
public class GameLevel {
    public final String modeId;
    public final int number;
    public final String voiceId;

    /** برای find_source و who_made_sound: شناسه صدایی که پخش می‌شود. */
    public String soundId;
    /** گزینه‌ها: برای find_source شناسه مکان، برای who_made_sound شناسه صدا. */
    public final List<String> options = new ArrayList<>();
    /** شناسه گزینه درست. */
    public String answerId;

    /** برای sequence: ترتیب صداها. */
    public final List<String> sequence = new ArrayList<>();

    /** برای audio_mission. */
    public String sceneTitle;
    public String backgroundName;
    public final List<String> layers = new ArrayList<>();
    public final List<Integer> countOptions = new ArrayList<>();
    public int answerCount;

    public GameLevel(String modeId, int number, String voiceId) {
        this.modeId = modeId;
        this.number = number;
        this.voiceId = voiceId;
    }

    public int getLevelNumber() { return number; }
}
