package ir.brandimo.goshyar.data;

/** یک مکان (جنگل، غار، خانه و ...) که در بازی «پیدا کردن منبع صدا» گزینه است. */
public class PlaceItem {
    public final String id;
    public final String title;
    public final String imageName;

    public PlaceItem(String id, String title, String imageName) {
        this.id = id;
        this.title = title;
        this.imageName = imageName;
    }
}
