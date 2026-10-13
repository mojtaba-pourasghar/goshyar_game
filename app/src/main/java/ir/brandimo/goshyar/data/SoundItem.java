package ir.brandimo.goshyar.data;

/** یک صدا در بانک صداها: نام فارسی، تصویر و فایل صوتی آن. */
public class SoundItem {
    public final String id;
    public final String title;
    public final String category;
    public final String imageName;
    public final String audioPath;

    public SoundItem(String id, String title, String category, String imageName, String audioPath) {
        this.id = id;
        this.title = title;
        this.category = category;
        this.imageName = imageName;
        this.audioPath = audioPath;
    }
}
