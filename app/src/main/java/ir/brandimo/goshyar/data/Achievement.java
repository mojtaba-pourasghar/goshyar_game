package ir.brandimo.goshyar.data;

public class Achievement {
    private String id;
    private String title;
    private String description;
    private boolean isUnlocked;
    private int iconResId;

    public Achievement(String id, String title, String description, boolean isUnlocked, int iconResId) {
        this.id = id;
        this.title = title;
        this.description = description;
        this.isUnlocked = isUnlocked;
        this.iconResId = iconResId;
    }

    public String getId() { return id; }
    public String getTitle() { return title; }
    public String getDescription() { return description; }
    public boolean isUnlocked() { return isUnlocked; }
    public int getIconResId() { return iconResId; }
}
