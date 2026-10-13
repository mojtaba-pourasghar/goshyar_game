package ir.brandimo.goshyar.ui.categories;

import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageView;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.fragment.app.Fragment;
import androidx.recyclerview.widget.GridLayoutManager;
import androidx.recyclerview.widget.RecyclerView;

import java.util.List;

import ir.brandimo.goshyar.R;
import ir.brandimo.goshyar.audio.AudioManagerHelper;
import ir.brandimo.goshyar.data.GameCategory;
import ir.brandimo.goshyar.data.GameContent;
import ir.brandimo.goshyar.databinding.FragmentCategorySelectBinding;

/** شش دسته صدا را از levels.json نشان می‌دهد و نام هر دسته را با گوینده می‌خواند. */
public class CategorySelectFragment extends Fragment {

    private FragmentCategorySelectBinding binding;

    @Nullable
    @Override
    public View onCreateView(@NonNull LayoutInflater inflater, @Nullable ViewGroup container,
                             @Nullable Bundle savedInstanceState) {
        binding = FragmentCategorySelectBinding.inflate(inflater, container, false);
        return binding.getRoot();
    }

    @Override
    public void onViewCreated(@NonNull View view, @Nullable Bundle savedInstanceState) {
        super.onViewCreated(view, savedInstanceState);

        List<GameCategory> cats = GameContent.get(requireContext()).allCategories();
        binding.rvCategories.setLayoutManager(new GridLayoutManager(requireContext(), 2));
        binding.rvCategories.setAdapter(new CategoryAdapter(cats));

        binding.btnCategoryBack.setOnClickListener(v -> requireActivity()
                .getOnBackPressedDispatcher().onBackPressed());
    }

    @Override
    public void onDestroyView() {
        super.onDestroyView();
        binding = null;
    }

    private static class CategoryAdapter extends RecyclerView.Adapter<CategoryAdapter.VH> {

        private final List<GameCategory> items;

        CategoryAdapter(List<GameCategory> items) { this.items = items; }

        @NonNull
        @Override
        public VH onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
            View v = LayoutInflater.from(parent.getContext())
                    .inflate(R.layout.item_category_tile, parent, false);
            return new VH(v);
        }

        @Override
        public void onBindViewHolder(@NonNull VH h, int position) {
            GameCategory c = items.get(position);
            h.label.setText(c.title);
            h.icon.setImageResource(GameContent.drawableId(h.itemView.getContext(),
                    c.iconName, R.drawable.ic_grid));

            // هر دسته کاشی رنگی خودش را می‌گیرد، به ترتیب همان رنگ‌های طرح
            int[] tiles = { R.drawable.tile_orange, R.drawable.tile_green, R.drawable.tile_cyan,
                            R.drawable.tile_pink, R.drawable.tile_purple, R.drawable.tile_blue };
            h.itemView.setBackgroundResource(tiles[position % tiles.length]);

            h.itemView.setOnClickListener(v -> {
                AudioManagerHelper.getInstance().playTapSound();
                AudioManagerHelper.getInstance().playVoice("v_cat_" + c.id);
            });
        }

        @Override
        public int getItemCount() { return items.size(); }

        static class VH extends RecyclerView.ViewHolder {
            final ImageView icon;
            final TextView label;

            VH(View v) {
                super(v);
                icon = v.findViewById(R.id.img_cat_icon);
                label = v.findViewById(R.id.tv_cat_title);
            }
        }
    }
}
