package ir.brandimo.goshyar.ui.dialogs;

import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.fragment.app.DialogFragment;

import ir.brandimo.goshyar.R;
import ir.brandimo.goshyar.databinding.DialogRewardSuccessBinding;
import ir.brandimo.goshyar.ui.views.MascotView;

/** دیالوگ «آفرین!» با امتیاز گرفته‌شده و مدال تازه، اگر مدالی باز شده باشد. */
public class RewardSuccessDialog extends DialogFragment {

    private static final String ARG_POINTS = "points";
    private static final String ARG_LAST = "last";
    private static final String ARG_BADGE = "badge";

    private DialogRewardSuccessBinding binding;
    private Runnable onNext;

    public static RewardSuccessDialog newInstance(int points, boolean isLastLevel, @Nullable String badgeTitle) {
        RewardSuccessDialog d = new RewardSuccessDialog();
        Bundle b = new Bundle();
        b.putInt(ARG_POINTS, points);
        b.putBoolean(ARG_LAST, isLastLevel);
        b.putString(ARG_BADGE, badgeTitle);
        d.setArguments(b);
        return d;
    }

    public RewardSuccessDialog setOnNext(Runnable r) {
        this.onNext = r;
        return this;
    }

    @Nullable
    @Override
    public View onCreateView(@NonNull LayoutInflater inflater, @Nullable ViewGroup container,
                             @Nullable Bundle savedInstanceState) {
        binding = DialogRewardSuccessBinding.inflate(inflater, container, false);
        return binding.getRoot();
    }

    @Override
    public void onViewCreated(@NonNull View view, @Nullable Bundle savedInstanceState) {
        super.onViewCreated(view, savedInstanceState);
        Bundle args = getArguments() != null ? getArguments() : Bundle.EMPTY;

        binding.mascotReward.setPose(MascotView.Pose.CELEBRATING);
        binding.tvRewardPoints.setText(getString(R.string.points_gained, args.getInt(ARG_POINTS, 20)));

        String badge = args.getString(ARG_BADGE);
        if (badge != null && !badge.isEmpty()) {
            binding.tvNewBadge.setVisibility(View.VISIBLE);
            binding.tvNewBadge.setText(getString(R.string.new_badge_earned, badge));
        } else {
            binding.tvNewBadge.setVisibility(View.GONE);
        }

        binding.btnNextLevel.setText(args.getBoolean(ARG_LAST, false)
                ? getString(R.string.finish_game) : getString(R.string.next_level));

        binding.btnNextLevel.setOnClickListener(v -> {
            dismissAllowingStateLoss();
            if (onNext != null) onNext.run();
        });
    }

    @Override
    public void onDestroyView() {
        super.onDestroyView();
        binding = null;
    }
}
