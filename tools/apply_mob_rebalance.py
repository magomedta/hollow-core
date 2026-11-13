"""
Applies rebalanced speed, damage, and health to all mobs.
Ensures fair survival gameplay: mobs can be outrun by player sprint (5.6 m/s),
deal survivable damage (8-20 per hit instead of 25-45), and have fair health pools.
"""
import os

rebalances = {
    'hollow_core/scripts/abyssal_glider.gd': [
        ('var max_health: float = 55.0', 'var max_health: float = 35.0'),
        ('var current_health: float = 55.0', 'var current_health: float = 35.0'),
        ('var cruise_speed: float = 6.0', 'var cruise_speed: float = 3.2'),
        ('var swoop_speed: float = 12.5', 'var swoop_speed: float = 6.5'),
        ('var attack_damage: float = 24.0', 'var attack_damage: float = 10.0')
    ],
    'hollow_core/scripts/cave_wyrm.gd': [
        ('var max_health: float = 140.0', 'var max_health: float = 85.0'),
        ('var current_health: float = 140.0', 'var current_health: float = 85.0'),
        ('var burrow_speed: float = 3.8', 'var burrow_speed: float = 2.4'),
        ('var bite_damage: float = 35.0', 'var bite_damage: float = 12.0')
    ],
    'hollow_core/scripts/geode_golem.gd': [
        ('var max_health: float = 250.0', 'var max_health: float = 140.0'),
        ('var current_health: float = 250.0', 'var current_health: float = 140.0'),
        ('var move_speed: float = 1.9', 'var move_speed: float = 1.3'),
        ('var attack_damage: float = 45.0', 'var attack_damage: float = 20.0'),
        ('var slam_radius: float = 5.5', 'var slam_radius: float = 3.8')
    ],
    'hollow_core/scripts/spore_spitter.gd': [
        ('var max_health: float = 65.0', 'var max_health: float = 40.0'),
        ('var current_health: float = 65.0', 'var current_health: float = 40.0'),
        ('var acid_damage: float = 18.0', 'var acid_damage: float = 8.0')
    ],
    'hollow_core/scripts/magma_basilisk.gd': [
        ('var max_health: float = 120.0', 'var max_health: float = 75.0'),
        ('var current_health: float = 120.0', 'var current_health: float = 75.0'),
        ('var move_speed: float = 5.2', 'var move_speed: float = 3.4'),
        ('var attack_damage: float = 34.0', 'var attack_damage: float = 14.0')
    ],
    'hollow_core/scripts/pale_stalker.gd': [
        ('var max_health: float = 70.0', 'var max_health: float = 45.0'),
        ('var current_health: float = 70.0', 'var current_health: float = 45.0'),
        ('var crawl_speed: float = 6.5', 'var crawl_speed: float = 3.6'),
        ('var stalk_speed: float = 1.8', 'var stalk_speed: float = 1.2'),
        ('var attack_damage: float = 38.0', 'var attack_damage: float = 15.0')
    ],
    'hollow_core/scripts/wall_mimic.gd': [
        ('var max_health: float = 85.0', 'var max_health: float = 50.0'),
        ('var current_health: float = 85.0', 'var current_health: float = 50.0'),
        ('var attack_damage: float = 38.0', 'var attack_damage: float = 16.0'),
        ('var lunge_speed: float = 7.0', 'var lunge_speed: float = 4.0')
    ]
}

def main():
    for path, pairs in rebalances.items():
        if not os.path.exists(path):
            print(f"Skipping missing: {path}")
            continue
        with open(path, 'r', encoding='utf-8') as f:
            txt = f.read()
        for old_s, new_s in pairs:
            if old_s in txt:
                txt = txt.replace(old_s, new_s)
            else:
                print(f"  WARNING: Could not find '{old_s}' in {path}")
        with open(path, 'w', encoding='utf-8') as f:
            f.write(txt)
        print(f"Successfully rebalanced: {path}")

if __name__ == "__main__":
    main()
