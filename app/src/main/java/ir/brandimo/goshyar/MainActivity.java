package ir.brandimo.goshyar;

import android.os.Bundle;
import android.view.View;
import androidx.appcompat.app.AppCompatActivity;
import androidx.fragment.app.Fragment;
import com.google.android.material.bottomnavigation.BottomNavigationView;

import ir.brandimo.goshyar.data.ChildProgress;
import ir.brandimo.goshyar.ui.achievements.AchievementsFragment;
import ir.brandimo.goshyar.ui.intro.IntroFragment;
import ir.brandimo.goshyar.ui.menu.MainMenuFragment;
import ir.brandimo.goshyar.ui.profile.ChildProfileFragment;
import ir.brandimo.goshyar.ui.splash.SplashFragment;

public class MainActivity extends AppCompatActivity {

    private BottomNavigationView bottomNav;
    private ChildProgress childProgress;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        childProgress = new ChildProgress("آرین", 3, 1250, 24, 5);

        bottomNav = findViewById(R.id.bottom_navigation);
        bottomNav.setOnItemSelectedListener(item -> {
            int id = item.getItemId();
            if (id == R.id.nav_home) {
                replaceFragment(new MainMenuFragment());
                return true;
            } else if (id == R.id.nav_achievements) {
                replaceFragment(new AchievementsFragment());
                return true;
            } else if (id == R.id.nav_profile) {
                replaceFragment(new ChildProfileFragment());
                return true;
            }
            return false;
        });

        // Start with Splash Fragment
        setBottomNavVisible(false);
        replaceFragment(new SplashFragment());
    }

    public void replaceFragment(Fragment fragment) {
        getSupportFragmentManager()
                .beginTransaction()
                .replace(R.id.fragment_container, fragment)
                .commit();
    }

    public void setBottomNavVisible(boolean visible) {
        if (bottomNav != null) {
            bottomNav.setVisibility(visible ? View.VISIBLE : View.GONE);
        }
    }

    public ChildProgress getChildProgress() {
        return childProgress;
    }
}
