package ir.brandimo.goshyar.ui.parent;

import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.fragment.app.Fragment;

import ir.brandimo.goshyar.R;
import ir.brandimo.goshyar.data.GameContent;
import ir.brandimo.goshyar.data.GameMode;
import ir.brandimo.goshyar.data.ProgressStore;
import ir.brandimo.goshyar.databinding.FragmentParentDashboardBinding;

/** پنل والدین: گزارش پیشرفت واقعی کودک بر اساس مراحل انجام‌شده. */
public class ParentDashboardFragment extends Fragment {

    private FragmentParentDashboardBinding binding;

    @Nullable
    @Override
    public View onCreateView(@NonNull LayoutInflater inflater, @Nullable ViewGroup container,
                             @Nullable Bundle savedInstanceState) {
        binding = FragmentParentDashboardBinding.inflate(inflater, container, false);
        return binding.getRoot();
    }

    @Override
    public void onViewCreated(@NonNull View view, @Nullable Bundle savedInstanceState) {
        super.onViewCreated(view, savedInstanceState);

        GameContent c = GameContent.get(requireContext());
        ProgressStore p = ProgressStore.get(requireContext());

        // هر حالت بازی یک مهارت را می‌سنجد
        bindSkill(binding.tvSkillFocus, binding.progressFocus,
                getString(R.string.skill_listening_focus), GameMode.FIND_SOURCE, c, p);
        bindSkill(binding.tvSkillRecognition, binding.progressRecognition,
                getString(R.string.skill_sound_recognition), GameMode.WHO_MADE_SOUND, c, p);
        bindSkill(binding.tvSkillMemory, binding.progressMemory,
                getString(R.string.skill_audio_memory), GameMode.SEQUENCE, c, p);
        bindSkill(binding.tvSkillMission, binding.progressMission,
                getString(R.string.mode_audio_mission), GameMode.AUDIO_MISSION, c, p);

        binding.tvParentPoints.setText(getString(R.string.points_label, p.totalPoints()));
        binding.tvParentMedals.setText(getString(R.string.medals_earned_count, p.medalsCount()));
        binding.tvParentStreak.setText(String.valueOf(p.bestStreak()));

        binding.btnParentBack.setOnClickListener(v -> requireActivity()
                .getOnBackPressedDispatcher().onBackPressed());
    }

    private void bindSkill(android.widget.TextView label, android.widget.ProgressBar bar,
                           String title, String modeId, GameContent c, ProgressStore p) {
        var mode = c.mode(modeId);
        int total = mode != null ? mode.levelCount() : 0;
        int done = p.completedInMode(modeId);
        label.setText(getString(R.string.parent_skill_summary, title, done, total));
        bar.setMax(Math.max(1, total));
        bar.setProgress(done);
    }

    @Override
    public void onDestroyView() {
        super.onDestroyView();
        binding = null;
    }
}
