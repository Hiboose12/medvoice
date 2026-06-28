def hide_hero_header(file_path):
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    target = """                    _HeroHeader(
                      role: config.label,
                      title: pageTitle,
                      subtitle: _pageSubtitle(widget.role, widget.page),
                      color: config.color,
                    ),"""
    
    replacement = """                    if (widget.page != OperationalPage.categories)
                      _HeroHeader(
                        role: config.label,
                        title: pageTitle,
                        subtitle: _pageSubtitle(widget.role, widget.page),
                        color: config.color,
                      ),"""
                      
    if target in content:
        content = content.replace(target, replacement)
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(content)
        print("Success")
    else:
        print("Target not found")

hide_hero_header('lib/features/operations/presentation/screens/operational_screen.dart')
