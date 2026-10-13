package ir.brandimo.goshyar.data;

import java.util.ArrayList;
import java.util.List;

public class GameMode {
    public static final String FIND_SOURCE = "find_source";
    public static final String WHO_MADE_SOUND = "who_made_sound";
    public static final String SEQUENCE = "sequence";
    public static final String AUDIO_MISSION = "audio_mission";

    public final String id;
    public final String title;
    public final String instruction;
    public final String iconName;
    public final String color;
    public final List<GameLevel> levels = new ArrayList<>();

    public GameMode(String id, String title, String instruction, String iconName, String color) {
        this.id = id;
        this.title = title;
        this.instruction = instruction;
        this.iconName = iconName;
        this.color = color;
    }

    public int levelCount() { return levels.size(); }

    public GameLevel level(int index) {
        if (index < 0 || index >= levels.size()) return null;
        return levels.get(index);
    }
}
