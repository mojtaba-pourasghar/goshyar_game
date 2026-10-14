package ir.brandimo.goshyar.ui.profile;

import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.fragment.app.Fragment;

import ir.brandimo.goshyar.R;
import ir.brandimo.goshyar.data.GameContent;
import ir.brandimo.goshyar.data.ProgressStore;
import ir.brandimo.goshyar.databinding.FragmentChildProfileBinding;
import ir.brandimo.goshyar.ui.parent.ParentGateDialog;

/** پروفایل کودک با امتیاز، سطح و مدال‌های واقعی از ProgressStore. */
public class ChildProfileFragment extends Fragment {

    private FragmentChildProfileBinding binding;

    @Nullable
    @Override
    public View onCreateView(@NonNull LayoutInflater inflater, @Nullable ViewGroup container,
                             @Nullable Bundle savedInstanceState) {
        binding = FragmentChildProfileBinding.inflate(inflater, container, false);
        return binding.getRoot();
    }

    @Override
    public void onViewCreated(@NonNull View view, @Nullable Bundle savedInstanceState) {
        super.onViewCreated(view, savedInstanceState);

        ProgressStore p = ProgressStore.get(requireContext());
        GameContent c = GameContent.get(requireContext());

        binding.tvChildName.setText(p.childName());
        binding.tvProfileLevel.setText(getString(R.string.level_label, p.level()));
        binding.tvProfilePoints.setText(getString(R.string.points_label, p.totalPoints()));
        binding.tvGamesCompleted.setText(getString(R.string.games_completed_count, p.completedCount()));
        binding.tvMedals.setText(getString(R.string.medals_earned_count, p.medalsCount()));

        int done = p.completedCount();
        int total = Math.max(1, c.totalLevels());
        binding.progressOverall.setMax(total);
        binding.progressOverall.setProgress(done);
        binding.tvOverallProgress.setText(getString(R.string.overall_progress, done, total));

        binding.btnOpenParentPanel.setOnClickListener(v ->
                new ParentGateDialog().show(getParentFragmentManager(), "ParentGate"));
    }

    @Override
    public void onDestroyView() {
        super.onDestroyView();
        binding = null;
    }
}
