from django.db import models
from django.contrib.auth.models import User


class Case(models.Model):
    STATUS_PENDING = 'Pending'
    STATUS_ACTIVE = 'Active'
    STATUS_SOLVED = 'Solved'
    STATUS_REJECTED = 'Rejected'

    URGENCY_HIGH = 'High'
    URGENCY_MEDIUM = 'Medium'
    URGENCY_LOW = 'Low'

    STATUS_CHOICES = [
        (STATUS_PENDING, STATUS_PENDING),
        (STATUS_ACTIVE, STATUS_ACTIVE),
        (STATUS_SOLVED, STATUS_SOLVED),
        (STATUS_REJECTED, STATUS_REJECTED),
    ]

    URGENCY_CHOICES = [
        (URGENCY_HIGH, URGENCY_HIGH),
        (URGENCY_MEDIUM, URGENCY_MEDIUM),
        (URGENCY_LOW, URGENCY_LOW),
    ]

    name = models.CharField(max_length=255)
    age = models.PositiveSmallIntegerField(default=0)
    location = models.CharField(max_length=255)
    description = models.TextField(blank=True)
    reliability = models.PositiveSmallIntegerField(default=50)
    urgency = models.CharField(max_length=16, choices=URGENCY_CHOICES, default=URGENCY_MEDIUM)
    status = models.CharField(max_length=16, choices=STATUS_CHOICES, default=STATUS_PENDING)
    photo = models.ImageField(upload_to='cases/', null=True, blank=True)
    user = models.ForeignKey(
        User,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='cases',
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return f'{self.name} ({self.status})'


class Tip(models.Model):
    case = models.ForeignKey(Case, on_delete=models.CASCADE, related_name='tips')
    user = models.ForeignKey(
        User,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='tips_submitted',
    )
    reporter = models.CharField(max_length=120, default='Anonymous')
    content = models.TextField()
    is_anonymous = models.BooleanField(default=False)
    share_location = models.BooleanField(default=False)
    verified = models.BooleanField(default=False)
    attachment = models.ImageField(upload_to='tips/', null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return f'Tip #{self.pk} for case #{self.case_id}'


class HonourProfile(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='honour_profile')
    score = models.PositiveIntegerField(default=0)
    medals = models.JSONField(default=list, blank=True)

    def __str__(self):
        return f'{self.user.username} ({self.score})'


class Reward(models.Model):
    name = models.CharField(max_length=200)
    description = models.TextField(blank=True)
    points_required = models.PositiveIntegerField(default=0)
    image = models.ImageField(upload_to='rewards/', null=True, blank=True)
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return self.name


class RewardRedemption(models.Model):
    STATUS_PENDING = 'Pending'
    STATUS_APPROVED = 'Approved'
    STATUS_REJECTED = 'Rejected'

    STATUS_CHOICES = [
        (STATUS_PENDING, STATUS_PENDING),
        (STATUS_APPROVED, STATUS_APPROVED),
        (STATUS_REJECTED, STATUS_REJECTED),
    ]

    reward = models.ForeignKey(Reward, on_delete=models.CASCADE, related_name='redemptions')
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='reward_redemptions')
    status = models.CharField(max_length=16, choices=STATUS_CHOICES, default=STATUS_PENDING)
    requested_at = models.DateTimeField(auto_now_add=True)
    reviewed_at = models.DateTimeField(null=True, blank=True)
    reviewed_by = models.ForeignKey(
        User,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='reward_reviews',
    )
    review_notes = models.TextField(blank=True)

    class Meta:
        ordering = ['-requested_at']

    def __str__(self):
        return f'{self.reward.name} for {self.user.username}'


class UserCoupon(models.Model):
    STATUS_ACTIVE = 'Active'
    STATUS_USED = 'Used'
    STATUS_EXPIRED = 'Expired'

    STATUS_CHOICES = [
        (STATUS_ACTIVE, STATUS_ACTIVE),
        (STATUS_USED, STATUS_USED),
        (STATUS_EXPIRED, STATUS_EXPIRED),
    ]

    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='coupons')
    reward = models.ForeignKey(Reward, on_delete=models.CASCADE, related_name='user_coupons')
    status = models.CharField(max_length=16, choices=STATUS_CHOICES, default=STATUS_ACTIVE)
    issued_at = models.DateTimeField(auto_now_add=True)
    used_at = models.DateTimeField(null=True, blank=True)
    expiry_date = models.DateTimeField(null=True, blank=True)
    redemption = models.OneToOneField(
        RewardRedemption,
        on_delete=models.CASCADE,
        null=True,
        blank=True,
        related_name='coupon',
    )

    class Meta:
        ordering = ['-issued_at']

    def __str__(self):
        return f'{self.reward.name} coupon for {self.user.username} ({self.status})'
