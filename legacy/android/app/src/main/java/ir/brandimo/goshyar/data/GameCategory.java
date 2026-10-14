package ir.brandimo.goshyar.data;

public class GameCategory {
    public final String id;
    public final String title;
    public final String iconName;
    public final String color;

    public GameCategory(String id, String title, String iconName, String color) {
        this.id = id;
        this.title = title;
        this.iconName = iconName;
        this.color = color;
    }

    public String getId() { return id; }
    public String getTitle() { return title; }
}
