package ir.brandimo.goshyar.ui.games;

import android.os.Bundle;
import android.view.View;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.fragment.app.Fragment;

import java.util.List;

import ir.brandimo.goshyar.MainActivity;
import ir.brandimo.goshyar.audio.AudioManagerHelper;
import ir.brandimo.goshyar.data.Achievement;
import ir.brandimo.goshyar.data.GameContent;
import ir.brandimo.goshyar.data.GameLevel;
import ir.brandimo.goshyar.data.GameMode;
import ir.brandimo.goshyar.data.ProgressStore;
import ir.brandimo.goshyar.ui.dialogs.FeedbackTryAgainDialog;
import ir.brandimo.goshyar.ui.dialogs.RewardSuccessDialog;
import ir.brandimo.goshyar.ui.menu.MainMenuFragment;

/**
 * کارهای مشترک هر چهار بازی: نگه‌داشتن مرحله فعلی، امتیازدهی، دیالوگ‌ها،
 * رفتن به مرحله بعد و آزاد کردن صدا هنگام خروج.
 */
public abstract class BaseGameFragment extends Fragment {

    protected GameContent content;
    protected ProgressStore progress;
    protected AudioManagerHelper audio;
    protected GameMode mode;
    protected int levelIndex = 0;
    protected boolean firstTry = true;
    protected boolean answered = false;

    /** شناسه حالت بازی، مثل GameMode.WHO_MADE_SOUND */
    protected abstract String modeId();

    /** صفحه را برای مرحله فعلی از نو می‌چیند. */
    protected abstract void bindLevel(GameLevel level);

    @Override
    public void onViewCreated(@NonNull View view, @Nullable Bundle savedInstanceState) {
        super.onViewCreated(view, savedInstanceState);
        content = GameContent.get(requireContext());
        progress = ProgressStore.get(requireContext());
        audio = AudioManagerHelper.getInstance();
        mode = content.mode(modeId());
        if (mode == null || mode.levelCount() == 0) {
            goHome();
            return;
        }
        // از اولین مرحله‌ای که هنوز تمام نشده شروع کن
        levelIndex = progress.firstUnfinished(modeId());
        showCurrentLevel();
    }

    protected GameLevel currentLevel() { return mode.level(levelIndex); }

    protected void showCurrentLevel() {
        GameLevel lvl = currentLevel();
        if (lvl == null) { goHome(); return; }
        firstTry = true;
        answered = false;
        bindLevel(lvl);
    }

    /** پاسخ کاربر را داوری می‌کند و بازخورد نشان می‌دهد. */
    protected void submitAnswer(boolean correct) {
        if (answered) return;
        GameLevel lvl = currentLevel();
        if (lvl == null) return;

        if (correct) {
            answered = true;
            int pts = progress.pointsForCorrect(firstTry);
            audio.playSuccessSound();
            List<Achievement> fresh = progress.onCorrect(modeId(), lvl.number, firstTry);
            audio.playVoice(firstTry ? "v_correct_1" : "v_correct_4");

            boolean last = levelIndex >= mode.levelCount() - 1;
            String badge = fresh.isEmpty() ? null : fresh.get(0).title;
            RewardSuccessDialog.newInstance(pts, last, badge)
                    .setOnNext(this::nextLevel)
                    .show(getParentFragmentManager(), "reward");
        } else {
            firstTry = false;
            progress.onWrong();
            audio.playFailSound();
            audio.playVoice("v_wrong_1");
            new FeedbackTryAgainDialog().show(getParentFragmentManager(), "tryagain");
        }
    }

    protected void nextLevel() {
        if (levelIndex >= mode.levelCount() - 1) {
            audio.playVoice("v_mode_done");
            goHome();
        } else {
            levelIndex++;
            showCurrentLevel();
        }
    }

    protected void goHome() {
        if (getActivity() instanceof MainActivity) {
            ((MainActivity) getActivity()).replaceFragment(new MainMenuFragment());
        }
    }

    @Override
    public void onPause() {
        super.onPause();
        if (audio != null) audio.stopAll();
    }
}
