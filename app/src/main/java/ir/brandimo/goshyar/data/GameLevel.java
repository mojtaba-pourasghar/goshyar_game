package ir.brandimo.goshyar.data;

import java.util.List;

public class GameLevel {
    private int levelNumber;
    private int maxLevels;
    private String promptText;
    private String targetSound;
    private int correctIndex;
    private List<OptionItem> options;

    public static class OptionItem {
        private String id;
        private String name;
        private int imageResId;

        public OptionItem(String id, String name, int imageResId) {
            this.id = id;
            this.name = name;
            this.imageResId = imageResId;
        }

        public String getId() { return id; }
        public String getName() { return name; }
        public int getImageResId() { return imageResId; }
    }

    public GameLevel(int levelNumber, int maxLevels, String promptText, String targetSound, int correctIndex, List<OptionItem> options) {
        this.levelNumber = levelNumber;
        this.maxLevels = maxLevels;
        this.promptText = promptText;
        this.targetSound = targetSound;
        this.correctIndex = correctIndex;
        this.options = options;
    }

    public int getLevelNumber() { return levelNumber; }
    public int getMaxLevels() { return maxLevels; }
    public String getPromptText() { return promptText; }
    public String getTargetSound() { return targetSound; }
    public int getCorrectIndex() { return correctIndex; }
    public List<OptionItem> getOptions() { return options; }
}
