package ir.brandimo.goshyar.ui.menu;

import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.fragment.app.Fragment;

import ir.brandimo.goshyar.MainActivity;
import ir.brandimo.goshyar.R;
import ir.brandimo.goshyar.audio.AudioManagerHelper;
import ir.brandimo.goshyar.data.ProgressStore;
import ir.brandimo.goshyar.databinding.FragmentMainMenuBinding;
import ir.brandimo.goshyar.ui.categories.CategorySelectFragment;
import ir.brandimo.goshyar.ui.games.AudioMissionGameFragment;
import ir.brandimo.goshyar.ui.games.FindSourceGameFragment;
import ir.brandimo.goshyar.ui.games.SequenceGameFragment;
import ir.brandimo.goshyar.ui.games.WhoMadeSoundGameFragment;

public class MainMenuFragment extends Fragment {

    private FragmentMainMenuBinding binding;

    @Nullable
    @Override
    public View onCreateView(@NonNull LayoutInflater inflater, @Nullable ViewGroup container,
                             @Nullable Bundle savedInstanceState) {
        binding = FragmentMainMenuBinding.inflate(inflater, container, false);
        return binding.getRoot();
    }

    @Override
    public void onViewCreated(@NonNull View view, @Nullable Bundle savedInstanceState) {
        super.onViewCreated(view, savedInstanceState);

        // امتیاز و نام واقعی کودک، نه مقدار ثابت
        ProgressStore p = ProgressStore.get(requireContext());
        binding.tvChildGreeting.setText(getString(R.string.hello_child, p.childName()));
        binding.tvPoints.setText(getString(R.string.points_label, p.totalPoints()));

        binding.cardModeFindSource.setOnClickListener(v -> go(new FindSourceGameFragment()));
        binding.cardModeWhoMadeSound.setOnClickListener(v -> go(new WhoMadeSoundGameFragment()));
        binding.cardModeSequence.setOnClickListener(v -> go(new SequenceGameFragment()));
        binding.cardModeAudioMission.setOnClickListener(v -> go(new AudioMissionGameFragment()));
        binding.btnAllCategories.setOnClickListener(v -> go(new CategorySelectFragment()));

        AudioManagerHelper.getInstance().playVoice("v_menu_greeting");
    }

    private void go(Fragment fragment) {
        AudioManagerHelper.getInstance().playTapSound();
        if (getActivity() instanceof MainActivity) {
            ((MainActivity) getActivity()).replaceFragment(fragment);
        }
    }

    @Override
    public void onDestroyView() {
        super.onDestroyView();
        binding = null;
    }
}
