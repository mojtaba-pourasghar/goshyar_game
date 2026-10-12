package ir.brandimo.goshyar.ui.parent;

import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.Toast;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.fragment.app.DialogFragment;
import ir.brandimo.goshyar.MainActivity;
import ir.brandimo.goshyar.databinding.DialogParentGateBinding;

public class ParentGateDialog extends DialogFragment {

    private DialogParentGateBinding binding;

    @Nullable
    @Override
    public View onCreateView(@NonNull LayoutInflater inflater, @Nullable ViewGroup container, @Nullable Bundle savedInstanceState) {
        binding = DialogParentGateBinding.inflate(inflater, container, false);
        return binding.getRoot();
    }

    @Override
    public void onViewCreated(@NonNull View view, @Nullable Bundle savedInstanceState) {
        super.onViewCreated(view, savedInstanceState);

        binding.btnVerifyGate.setOnClickListener(v -> {
            String ans = binding.etGateAnswer.getText().toString().trim();
            if ("7".equals(ans) || "۷".equals(ans)) {
                dismiss();
                if (getActivity() instanceof MainActivity) {
                    ((MainActivity) getActivity()).replaceFragment(new ParentDashboardFragment());
                }
            } else {
                Toast.makeText(getContext(), "پاسخ نادرست است. دوباره تلاش کنید.", Toast.LENGTH_SHORT).show();
            }
        });
    }

    @Override
    public void onDestroyView() {
        super.onDestroyView();
        binding = null;
    }
}
