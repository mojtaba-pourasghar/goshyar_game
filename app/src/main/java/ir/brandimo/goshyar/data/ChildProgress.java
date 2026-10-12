package ir.brandimo.goshyar.data;

public class ChildProgress {
    private String childName;
    private int level;
    private int totalPoints;
    private int completedGamesCount;
    private int medalsCount;

    public ChildProgress(String childName, int level, int totalPoints, int completedGamesCount, int medalsCount) {
        this.childName = childName;
        this.level = level;
        this.totalPoints = totalPoints;
        this.completedGamesCount = completedGamesCount;
        this.medalsCount = medalsCount;
    }

    public String getChildName() { return childName; }
    public int getLevel() { return level; }
    public int getTotalPoints() { return totalPoints; }
    public int getCompletedGamesCount() { return completedGamesCount; }
    public int getMedalsCount() { return medalsCount; }

    public void addPoints(int pts) {
        this.totalPoints += pts;
        this.completedGamesCount += 1;
        this.level = 1 + (this.totalPoints / 500);
    }
}
