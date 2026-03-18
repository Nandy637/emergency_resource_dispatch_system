import 'package:flutter/material.dart';

/// Settings Screen
/// Configure alternative SOS triggers (voice, shake) and app preferences
class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Toggle states for alternative triggers
  bool _voiceTrigger = false;
  bool _shakeTrigger = false;
  bool _doubleTapTrigger = false;
  bool _hapticFeedback = true;
  bool _soundAlerts = true;
  bool _locationSharing = true;
  
  // Emergency contact
  String _emergencyContact = "911";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Settings',
          style: TextStyle(color: Colors.white, fontSize: 20),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          // Alternative Triggers Section
          _buildSectionHeader("ALTERNATIVE TRIGGERS"),
          _buildSettingCard([
            _buildSwitchTile(
              icon: Icons.mic,
              title: "Voice Activation",
              subtitle: "Say 'Help' to trigger SOS",
              value: _voiceTrigger,
              onChanged: (value) => setState(() => _voiceTrigger = value),
            ),
            _buildDivider(),
            _buildSwitchTile(
              icon: Icons.vibration,
              title: "Shake to Trigger",
              subtitle: "Shake phone vigorously to send alert",
              value: _shakeTrigger,
              onChanged: (value) => setState(() => _shakeTrigger = value),
            ),
            _buildDivider(),
            _buildSwitchTile(
              icon: Icons.touch_app,
              title: "Double Tap",
              subtitle: "Tap SOS button twice quickly",
              value: _doubleTapTrigger,
              onChanged: (value) => setState(() => _doubleTapTrigger = value),
            ),
          ]),
          
          SizedBox(height: 24),
          
          // Feedback Section
          _buildSectionHeader("FEEDBACK & ALERTS"),
          _buildSettingCard([
            _buildSwitchTile(
              icon: Icons.touch_app,
              title: "Haptic Feedback",
              subtitle: "Vibrate when triggering SOS",
              value: _hapticFeedback,
              onChanged: (value) => setState(() => _hapticFeedback = value),
            ),
            _buildDivider(),
            _buildSwitchTile(
              icon: Icons.volume_up,
              title: "Sound Alerts",
              subtitle: "Play sound during emergency",
              value: _soundAlerts,
              onChanged: (value) => setState(() => _soundAlerts = value),
            ),
          ]),
          
          SizedBox(height: 24),
          
          // Privacy Section
          _buildSectionHeader("PRIVACY & SAFETY"),
          _buildSettingCard([
            _buildSwitchTile(
              icon: Icons.location_on,
              title: "Location Sharing",
              subtitle: "Share location with responders",
              value: _locationSharing,
              onChanged: (value) => setState(() => _locationSharing = value),
            ),
            _buildDivider(),
            _buildNavigationTile(
              icon: Icons.contact_phone,
              title: "Emergency Contact",
              subtitle: _emergencyContact,
              onTap: () => _showEmergencyContactDialog(),
            ),
          ]),
          
          SizedBox(height: 24),
          
          // About Section
          _buildSectionHeader("ABOUT"),
          _buildSettingCard([
            _buildNavigationTile(
              icon: Icons.info_outline,
              title: "App Version",
              subtitle: "2.4.1",
              onTap: () {},
            ),
            _buildDivider(),
            _buildNavigationTile(
              icon: Icons.description_outlined,
              title: "Terms of Service",
              subtitle: "",
              onTap: () {},
            ),
            _buildDivider(),
            _buildNavigationTile(
              icon: Icons.privacy_tip_outlined,
              title: "Privacy Policy",
              subtitle: "",
              onTap: () {},
            ),
          ]),
          
          SizedBox(height: 40),
          
          // Danger Zone
          _buildSectionHeader("DANGER ZONE"),
          _buildSettingCard([
            _buildActionTile(
              icon: Icons.delete_outline,
              title: "Delete All Data",
              subtitle: "Remove all stored information",
              iconColor: Colors.red,
              onTap: () => _showDeleteConfirmation(),
            ),
          ]),
          
          SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.only(left: 8, bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          color: Colors.grey[500],
          fontSize: 13,
          fontWeight: FontWeight.w600,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildSettingCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.red, size: 20),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: Colors.red, size: 20),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (subtitle.isNotEmpty)
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 13,
                      ),
                    ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey[600]),
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: iconColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      color: Colors.grey[800],
      height: 1,
      indent: 68,
    );
  }

  void _showEmergencyContactDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF1C1C1E),
        title: Text("Emergency Contact", style: TextStyle(color: Colors.white)),
        content: TextField(
          style: TextStyle(color: Colors.white),
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            hintText: "Enter phone number",
            hintStyle: TextStyle(color: Colors.grey),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.grey),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.red),
            ),
          ),
          controller: TextEditingController(text: _emergencyContact),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text("Save", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF1C1C1E),
        title: Text("Delete All Data?", style: TextStyle(color: Colors.white)),
        content: Text(
          "This action cannot be undone. All your settings and data will be permanently deleted.",
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
