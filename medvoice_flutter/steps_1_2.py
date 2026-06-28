import re

def update_operational_screen(file_path):
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    # Rename Entity Verification to Access Control in nav menu
    old_nav_item = """_NavItem(
          'Entity Verification',
          RoutePaths.adminEntityVerification,
          Icons.how_to_reg_outlined,
        ),"""
    new_nav_item = """_NavItem(
          'Access Control',
          RoutePaths.adminEntityVerification,
          Icons.how_to_reg_outlined,
        ),"""
    content = content.replace(old_nav_item, new_nav_item)

    # Rename page title
    content = content.replace(
        "OperationalPage.entityVerification => 'Entity Verification',",
        "OperationalPage.entityVerification => 'Access Control',"
    )
    
    # Update _PendingApprovalsSection Review onTap
    # Look for the Review button
    old_review_button = """onTap: () {}, // Could link to review
                          child: const Text('Review', style: TextStyle(color: AppColors.admin, fontWeight: FontWeight.w500)),"""
    new_review_button = """onTap: () {
                            context.push(RoutePaths.adminEntityVerification);
                          },
                          child: const Text('Review', style: TextStyle(color: AppColors.admin, fontWeight: FontWeight.w500)),"""
    content = content.replace(old_review_button, new_review_button)

    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)
        print("Updated operational_screen.dart (Steps 1 & 2)")

update_operational_screen(r'c:\Users\VICTUS\OneDrive\Desktop\medvoice\MedVoice\medvoice_flutter\lib\features\operations\presentation\screens\operational_screen.dart')
