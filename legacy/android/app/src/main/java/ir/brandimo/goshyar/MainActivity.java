package ir.brandimo.goshyar;

import android.os.Bundle;
import android.view.View;

import androidx.activity.OnBackPressedCallback;
import androidx.appcompat.app.AppCompatActivity;
import androidx.fragment.app.Fragment;
import androidx.fragment.app.FragmentManager;

import com.google.android.material.bottomnavigation.BottomNavigationView;

import ir.brandimo.goshyar.audio.AudioManagerHelper;
import ir.brandimo.goshyar.ui.achievements.AchievementsFragment;
import ir.brandimo.goshyar.ui.menu.MainMenuFragment;
import ir.brandimo.goshyar.ui.profile.ChildProfileFragment;
import ir.brandimo.goshyar.ui.splash.SplashFragment;

public class MainActivity extends AppCompatActivity {

    private BottomNavigationView bottomNav;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        bottomNav = findViewById(R.id.bottom_navigation);
        bottomNav.setOnItemSelectedListener(item -> {
            int id = item.getItemId();
            if (id == R.id.nav_home) { replaceFragment(new MainMenuFragment()); return true; }
            if (id == R.id.nav_achievements) { replaceFragment(new AchievementsFragment()); return true; }
            if (id == R.id.nav_profile) { replaceFragment(new ChildProfileFragment()); return true; }
            return false;
        });

        // دکمه بازگشت گوشی باید در پشته صفحه‌ها عقب برود، نه اینکه از برنامه خارج شود.
        getOnBackPressedDispatcher().addCallback(this, new OnBackPressedCallback(true) {
            @Override
            public void handleOnBackPressed() {
                FragmentManager fm = getSupportFragmentManager();
                if (fm.getBackStackEntryCount() > 0) {
                    fm.popBackStack();
                } else {
                    setEnabled(false);
                    getOnBackPressedDispatcher().onBackPressed();
                }
            }
        });

        if (savedInstanceState == null) {
            setBottomNavVisible(false);
            replaceFragment(new SplashFragment(), false);
        }
    }

    public void replaceFragment(Fragment fragment) {
        replaceFragment(fragment, true);
    }

    public void replaceFragment(Fragment fragment, boolean addToBackStack) {
        AudioManagerHelper.getInstance().stopAll();
        var tx = getSupportFragmentManager().beginTransaction()
                .replace(R.id.fragment_container, fragment);
        if (addToBackStack) tx.addToBackStack(null);
        tx.commit();
    }

    public void setBottomNavVisible(boolean visible) {
        if (bottomNav != null) bottomNav.setVisibility(visible ? View.VISIBLE : View.GONE);
    }

    @Override
    protected void onStop() {
        super.onStop();
        AudioManagerHelper.getInstance().stopAll();
    }
}
