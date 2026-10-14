package ir.brandimo.goshyar.ui.achievements;

import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.core.content.ContextCompat;
import androidx.fragment.app.Fragment;

import ir.brandimo.goshyar.R;
import ir.brandimo.goshyar.data.Achievement;
import ir.brandimo.goshyar.data.GameContent;
import ir.brandimo.goshyar.data.ProgressStore;
import ir.brandimo.goshyar.databinding.FragmentAchievementsBinding;

/** فهرست مدال‌ها از روی levels.json، با حالت باز/قفل بر اساس پیشرفت واقعی کودک. */
public class AchievementsFragment extends Fragment {

    private FragmentAchievementsBinding binding;

    @Nullable
    @Override
    public View onCreateView(@NonNull LayoutInflater inflater, @Nullable ViewGroup container,
                             @Nullable Bundle savedInstanceState) {
        binding = FragmentAchievementsBinding.inflate(inflater, container, false);
        return binding.getRoot();
    }

    @Override
    public void onViewCreated(@NonNull View view, @Nullable Bundle savedInstanceState) {
        super.onViewCreated(view, savedInstanceState);

        GameContent content = GameContent.get(requireContext());
        ProgressStore progress = ProgressStore.get(requireContext());
        progress.refreshBadges();

        binding.tvMedalsSummary.setText(getString(R.string.medals_earned_count, progress.medalsCount()));

        LinearLayout list = binding.listAchievements;
        list.removeAllViews();
        LayoutInflater inflater = LayoutInflater.from(requireContext());

        for (Achievement a : content.allAchievements()) {
            boolean unlocked = progress.isBadgeUnlocked(a.id);
            View row = inflater.inflate(R.layout.item_achievement, list, false);

            ((TextView) row.findViewById(R.id.tv_badge_title)).setText(a.title);
            ((TextView) row.findViewById(R.id.tv_badge_desc)).setText(a.desc);

            ImageView icon = row.findViewById(R.id.img_badge);
            icon.setImageResource(GameContent.drawableId(requireContext(), a.iconName,
                    R.drawable.ic_gold_star));
            icon.setAlpha(unlocked ? 1f : 0.3f);

            ImageView state = row.findViewById(R.id.img_badge_state);
            state.setImageResource(unlocked ? R.drawable.ic_check_green : R.drawable.ic_lock);
            state.setColorFilter(ContextCompat.getColor(requireContext(),
                    unlocked ? R.color.success_green : R.color.text_muted));

            list.addView(row);
        }
    }

    @Override
    public void onDestroyView() {
        super.onDestroyView();
        binding = null;
    }
}
