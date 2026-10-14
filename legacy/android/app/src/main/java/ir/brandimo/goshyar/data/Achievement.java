package ir.brandimo.goshyar.data;

public class Achievement {
    public final String id;
    public final String title;
    public final String desc;
    public final String iconName;
    /** قانون باز شدن، مثل "levels>=5" یا "cat:nature>=3" یا "mode:sequence>=4" یا "streak>=10" */
    public final String rule;

    public Achievement(String id, String title, String desc, String iconName, String rule) {
        this.id = id;
        this.title = title;
        this.desc = desc;
        this.iconName = iconName;
        this.rule = rule;
    }

    public String getId() { return id; }
    public String getTitle() { return title; }
    public String getDescription() { return desc; }
}
