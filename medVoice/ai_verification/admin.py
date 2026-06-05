from django.contrib import admin
from .models import TrainingData

@admin.register(TrainingData)
class TrainingDataAdmin(admin.ModelAdmin):
    list_display = ('id', 'is_hospital_related', 'ai_confidence', 'created_at', 'reviewed_by')
    list_filter = ('is_hospital_related', 'created_at')
    search_fields = ('text_content',)
    readonly_fields = ('created_at',)
    
    actions = ['mark_as_relevant', 'mark_as_irrelevant']

    def mark_as_relevant(self, request, queryset):
        queryset.update(is_hospital_related=True)
    mark_as_relevant.short_description = "Mark selected data as Relevant"

    def mark_as_irrelevant(self, request, queryset):
        queryset.update(is_hospital_related=False)
    mark_as_irrelevant.short_description = "Mark selected data as Irrelevant"
