package ir.brandimo.goshyar.ui.menu;

import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.fragment.app.Fragment;
import ir.brandimo.goshyar.MainActivity;
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
    public View onCreateView(@NonNull LayoutInflater inflater, @Nullable ViewGroup container, @Nullable Bundle savedInstanceState) {
        binding = FragmentMainMenuBinding.inflate(inflater, container, false);
        return binding.getRoot();
    }

    @Override
    public void onViewCreated(@NonNull View view, @Nullable Bundle savedInstanceState) {
        super.onViewCreated(view, savedInstanceState);

        binding.cardModeFindSource.setOnClickListener(v -> navigateTo(new FindSourceGameFragment()));
        binding.cardModeWhoMadeSound.setOnClickListener(v -> navigateTo(new WhoMadeSoundGameFragment()));
        binding.cardModeSequence.setOnClickListener(v -> navigateTo(new SequenceGameFragment()));
        binding.cardModeAudioMission.setOnClickListener(v -> navigateTo(new AudioMissionGameFragment()));
        binding.btnAllCategories.setOnClickListener(v -> navigateTo(new CategorySelectFragment()));
    }

    private void navigateTo(Fragment fragment) {
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
