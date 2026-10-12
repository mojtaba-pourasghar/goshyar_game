package ir.brandimo.goshyar.data;

public class GameCategory {
    private String id;
    private String title;
    private int iconResId;
    private int bgDrawableResId;

    public GameCategory(String id, String title, int iconResId, int bgDrawableResId) {
        this.id = id;
        this.title = title;
        this.iconResId = iconResId;
        this.bgDrawableResId = bgDrawableResId;
    }

    public String getId() { return id; }
    public String getTitle() { return title; }
    public int getIconResId() { return iconResId; }
    public int getBgDrawableResId() { return bgDrawableResId; }
}
