import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class WordView extends StatelessWidget {
  final String word;
  final int orpIndex;
  final double fontSize;
  final Color orpColor;
  final String fontFamily;
  final Color baseColor;
  final bool isHighlighted;
  final bool isRsvp;

  const WordView({
    super.key,
    required this.word,
    required this.orpIndex,
    required this.fontSize,
    required this.orpColor,
    required this.fontFamily,
    required this.baseColor,
    this.isHighlighted = false,
    this.isRsvp = true,
  });

  @override
  Widget build(BuildContext context) {
    if (isRsvp) {
      return _buildRsvpWord();
    } else {
      return _buildGlidingWord();
    }
  }

  Widget _buildRsvpWord() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(word.length, (i) {
        final isOrp = i == orpIndex;
        return Text(
          word[i],
          style: GoogleFonts.getFont(
            fontFamily,
            fontSize: fontSize,
            height: 1.1,
            fontWeight: FontWeight.w600,
            color: isOrp && orpColor != Colors.transparent ? orpColor : baseColor,
          ),
        );
      }),
    );
  }

  Widget _buildGlidingWord() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
      decoration: BoxDecoration(
        color: isHighlighted ? Colors.white.withValues(alpha: 0.15) : Colors.transparent,
        borderRadius: BorderRadius.circular(4.0),
      ),
      child: AnimatedDefaultTextStyle(
        duration: const Duration(milliseconds: 200),
        style: GoogleFonts.getFont(
          fontFamily,
          fontSize: fontSize,
          height: 1.4,
          fontWeight: isHighlighted ? FontWeight.w700 : FontWeight.w400,
          color: isHighlighted ? Colors.white : Colors.white.withValues(alpha: 0.25),
        ),
        child: Text(word),
      ),
    );
  }
}

class ModeButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const ModeButton({
    super.key,
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFF3B3B) : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? Colors.white : Colors.white60, size: 18),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class AiActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const AiActionTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: const Color(0xFFFF3B3B), size: 20),
      ),
      title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle, style: const TextStyle(color: Colors.white60, fontSize: 12)),
      trailing: const Icon(Icons.chevron_right, color: Colors.white24),
    );
  }
}
