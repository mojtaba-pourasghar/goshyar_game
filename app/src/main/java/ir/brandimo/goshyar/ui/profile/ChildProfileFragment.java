package ir.brandimo.goshyar.ui.profile;

import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.fragment.app.Fragment;
import ir.brandimo.goshyar.databinding.FragmentChildProfileBinding;
import ir.brandimo.goshyar.ui.parent.ParentGateDialog;

public class ChildProfileFragment extends Fragment {

    private FragmentChildProfileBinding binding;

    @Nullable
    @Override
    public View onCreateView(@NonNull LayoutInflater inflater, @Nullable ViewGroup container, @Nullable Bundle savedInstanceState) {
        binding = FragmentChildProfileBinding.inflate(inflater, container, false);
        return binding.getRoot();
    }

    @Override
    public void onViewCreated(@NonNull View view, @Nullable Bundle savedInstanceState) {
        super.onViewCreated(view, savedInstanceState);

        binding.btnOpenParentPanel.setOnClickListener(v -> {
            ParentGateDialog dialog = new ParentGateDialog();
            dialog.show(getParentFragmentManager(), "ParentGate");
        });
    }

    @Override
    public void onDestroyView() {
        super.onDestroyView();
        binding = null;
    }
}
