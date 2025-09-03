import 'package:flutter/material.dart';
import '../../data/models/user_model.dart';

class AvatarWidget extends StatelessWidget {
  final UserModel user;
  final double radius;
  final bool showInitials;

  const AvatarWidget({
    super.key,
    required this.user,
    this.radius = 20,
    this.showInitials = false,
  });

  @override
  Widget build(BuildContext context) {
    final iconData = _getIconData(user.avatarIconName);
    final color = _getColor(user.avatarColorName);

    return CircleAvatar(
      radius: radius,
      backgroundColor: color,
      child: showInitials
          ? Text(
              user.initials,
              style: TextStyle(
                color: Colors.white,
                fontSize: radius * 0.6,
                fontWeight: FontWeight.bold,
              ),
            )
          : Icon(
              iconData,
              color: Colors.white,
              size: radius * 0.8,
            ),
    );
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'person':
        return Icons.person;
      case 'work':
        return Icons.work;
      case 'star':
        return Icons.star;
      case 'favorite':
        return Icons.favorite;
      case 'home':
        return Icons.home;
      case 'school':
        return Icons.school;
      case 'sports':
        return Icons.sports;
      case 'music':
        return Icons.music_note;
      case 'movie':
        return Icons.movie;
      case 'game':
        return Icons.games;
      case 'code':
        return Icons.code;
      case 'palette':
        return Icons.palette;
      case 'camera':
        return Icons.camera_alt;
      case 'travel':
        return Icons.flight;
      case 'food':
        return Icons.restaurant;
      case 'nature':
        return Icons.nature;
      case 'tech':
        return Icons.computer;
      case 'book':
        return Icons.book;
      case 'heart':
        return Icons.favorite_border;
      default:
        return Icons.person;
    }
  }

  Color _getColor(String colorName) {
    switch (colorName) {
      case 'blue':
        return Colors.blue;
      case 'green':
        return Colors.green;
      case 'purple':
        return Colors.purple;
      case 'orange':
        return Colors.orange;
      case 'red':
        return Colors.red;
      case 'pink':
        return Colors.pink;
      case 'teal':
        return Colors.teal;
      case 'indigo':
        return Colors.indigo;
      case 'amber':
        return Colors.amber;
      case 'cyan':
        return Colors.cyan;
      case 'lime':
        return Colors.lime;
      case 'brown':
        return Colors.brown;
      case 'grey':
        return Colors.grey;
      case 'deepOrange':
        return Colors.deepOrange;
      case 'deepPurple':
        return Colors.deepPurple;
      case 'lightBlue':
        return Colors.lightBlue;
      case 'lightGreen':
        return Colors.lightGreen;
      default:
        return Colors.blue;
    }
  }
}

// Widget para seleccionar icono de avatar
class AvatarIconSelector extends StatelessWidget {
  final String? selectedIcon;
  final Function(String) onIconSelected;

  const AvatarIconSelector({
    super.key,
    this.selectedIcon,
    required this.onIconSelected,
  });

  @override
  Widget build(BuildContext context) {
    final icons = [
      'person',
      'work',
      'star',
      'favorite',
      'home',
      'school',
      'sports',
      'music',
      'movie',
      'game',
      'code',
      'palette',
      'camera',
      'travel',
      'food',
      'nature',
      'tech',
      'book',
      'heart'
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 6,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: icons.length,
      itemBuilder: (context, index) {
        final icon = icons[index];
        final isSelected = selectedIcon == icon;

        return GestureDetector(
          onTap: () => onIconSelected(icon),
          child: Container(
            decoration: BoxDecoration(
              color: isSelected ? Colors.blue : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected ? Colors.blue : Colors.grey.shade300,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Icon(
              _getIconData(icon),
              color: isSelected ? Colors.white : Colors.grey.shade600,
              size: 20,
            ),
          ),
        );
      },
    );
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'person':
        return Icons.person;
      case 'work':
        return Icons.work;
      case 'star':
        return Icons.star;
      case 'favorite':
        return Icons.favorite;
      case 'home':
        return Icons.home;
      case 'school':
        return Icons.school;
      case 'sports':
        return Icons.sports;
      case 'music':
        return Icons.music_note;
      case 'movie':
        return Icons.movie;
      case 'game':
        return Icons.games;
      case 'code':
        return Icons.code;
      case 'palette':
        return Icons.palette;
      case 'camera':
        return Icons.camera_alt;
      case 'travel':
        return Icons.flight;
      case 'food':
        return Icons.restaurant;
      case 'nature':
        return Icons.nature;
      case 'tech':
        return Icons.computer;
      case 'book':
        return Icons.book;
      case 'heart':
        return Icons.favorite_border;
      default:
        return Icons.person;
    }
  }
}

// Widget para seleccionar color de avatar
class AvatarColorSelector extends StatelessWidget {
  final String? selectedColor;
  final Function(String) onColorSelected;

  const AvatarColorSelector({
    super.key,
    this.selectedColor,
    required this.onColorSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colors = [
      'blue',
      'green',
      'purple',
      'orange',
      'red',
      'pink',
      'teal',
      'indigo',
      'amber',
      'cyan',
      'lime',
      'brown',
      'grey',
      'deepOrange',
      'deepPurple',
      'lightBlue',
      'lightGreen'
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 6,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: colors.length,
      itemBuilder: (context, index) {
        final colorName = colors[index];
        final color = _getColor(colorName);
        final isSelected = selectedColor == colorName;

        return GestureDetector(
          onTap: () => onColorSelected(colorName),
          child: Container(
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected ? Colors.black : Colors.grey.shade300,
                width: isSelected ? 3 : 1,
              ),
            ),
            child: isSelected
                ? const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 16,
                  )
                : null,
          ),
        );
      },
    );
  }

  Color _getColor(String colorName) {
    switch (colorName) {
      case 'blue':
        return Colors.blue;
      case 'green':
        return Colors.green;
      case 'purple':
        return Colors.purple;
      case 'orange':
        return Colors.orange;
      case 'red':
        return Colors.red;
      case 'pink':
        return Colors.pink;
      case 'teal':
        return Colors.teal;
      case 'indigo':
        return Colors.indigo;
      case 'amber':
        return Colors.amber;
      case 'cyan':
        return Colors.cyan;
      case 'lime':
        return Colors.lime;
      case 'brown':
        return Colors.brown;
      case 'grey':
        return Colors.grey;
      case 'deepOrange':
        return Colors.deepOrange;
      case 'deepPurple':
        return Colors.deepPurple;
      case 'lightBlue':
        return Colors.lightBlue;
      case 'lightGreen':
        return Colors.lightGreen;
      default:
        return Colors.blue;
    }
  }
}
