import 'package:flutter/material.dart';

/// Help On The Way Screen
/// Status Stepper UI showing incident response progress
class HelpOnTheWayScreen extends StatefulWidget {
  @override
  _HelpOnTheWayScreenState createState() => _HelpOnTheWayScreenState();
}

class _HelpOnTheWayScreenState extends State<HelpOnTheWayScreen> {
  // Current step in the response process
  int _currentStep = 1;
  
  final List<Map<String, dynamic>> _steps = [
    {
      'title': 'Alert Sent',
      'subtitle': 'Emergency services notified',
      'icon': Icons.send,
      'time': 'Just now',
    },
    {
      'title': 'Dispatched',
      'subtitle': '3 responders en route',
      'icon': Icons.local_shipping,
      'time': 'Just now',
    },
    {
      'title': 'On Scene',
      'subtitle': 'First responder arrived',
      'icon': Icons.location_on,
      'time': '2 min',
    },
    {
      'title': 'Assistance Provided',
      'subtitle': 'Getting help now',
      'icon': Icons.health_and_safety,
      'time': '5 min',
    },
  ];

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
          'Help is on the way',
          style: TextStyle(color: Colors.white, fontSize: 20),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Animated Status Indicator
          _buildStatusHeader(),
          
          // Timeline / Stepper
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              itemCount: _steps.length,
              itemBuilder: (context, index) {
                return _buildTimelineItem(index);
              },
            ),
          ),
          
          // Bottom Action Buttons
          _buildBottomActions(),
        ],
      ),
    );
  }

  Widget _buildStatusHeader() {
    return Container(
      padding: EdgeInsets.all(24),
      child: Column(
        children: [
          // Animated pulsing circle
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.8, end: 1.0),
            duration: Duration(milliseconds: 1000),
            curve: Curves.easeInOut,
            builder: (context, scale, child) {
              return Transform.scale(
                scale: scale,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 60,
                  ),
                ),
              );
            },
          ),
          SizedBox(height: 16),
          Text(
            'Emergency Alert Active',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Incident #EMG-2024-001',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(int index) {
    final step = _steps[index];
    final bool isCompleted = index < _currentStep;
    final bool isCurrent = index == _currentStep;
    
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          // Timeline indicator
          Column(
            children: [
              // Line before
              Container(
                width: 2,
                height: 20,
                color: isCompleted || isCurrent ? Colors.green : Colors.grey[800],
              ),
              // Circle indicator
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isCompleted 
                    ? Colors.green 
                    : (isCurrent ? Colors.green.withOpacity(0.3) : Colors.grey[800]),
                  shape: BoxShape.circle,
                  border: isCurrent 
                    ? Border.all(color: Colors.green, width: 2)
                    : null,
                ),
                child: Icon(
                  isCompleted ? Icons.check : step['icon'],
                  color: Colors.white,
                  size: 16,
                ),
              ),
              // Line after (if not last)
              if (index < _steps.length - 1)
                Container(
                  width: 2,
                  height: 40,
                  color: isCompleted ? Colors.green : Colors.grey[800],
                ),
            ],
          ),
          SizedBox(width: 16),
          // Content
          Expanded(
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        step['title'],
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        step['subtitle'],
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isCompleted 
                        ? Colors.green.withOpacity(0.2) 
                        : Colors.grey[800],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      step['time'],
                      style: TextStyle(
                        color: isCompleted ? Colors.green : Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: EdgeInsets.all(20),
      child: Row(
        children: [
          // Call 911 Button
          Expanded(
            child: Container(
              height: 56,
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.phone, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'Call 911',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(width: 12),
          // Message Button
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Color(0xFF1C1C1E),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.message,
              color: Colors.white,
            ),
          ),
          SizedBox(width: 12),
          // Share Location Button
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Color(0xFF1C1C1E),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.share_location,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
