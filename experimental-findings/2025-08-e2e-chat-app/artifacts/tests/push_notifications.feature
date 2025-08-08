# push_notifications.feature
# BDD scenarios for push notifications

Feature: Push Notifications
  As a user of the chat application
  I want to receive notifications when I'm not actively using the app
  So that I stay informed about new messages and events

  Background:
    Given the notification service is running
    And I am authenticated as "alice"
    And I have the mobile app installed

  Scenario: Register Device for Push Notifications
    Given I open the app on my device
    When I grant notification permissions
    Then my device should generate a push token
    And the token should be sent to the server
    And the server should store my device token
    And I should receive a confirmation
    And future notifications should be enabled

  Scenario: Receive Message Notification
    Given I have registered my device for notifications
    And the app is in the background
    When "bob" sends me a message "Hello Alice!"
    Then I should receive a push notification
    And the notification should show "New message from Bob"
    And the notification should include a preview "Hello Alice!"
    And the notification should play a sound
    And tapping the notification should open the chat

  Scenario: Notification Privacy Settings
    Given I have privacy mode enabled
    When I receive a message from "charlie"
    Then the notification should show "New message"
    And the sender name should be hidden
    And the message content should be hidden
    And only the app badge should update
    And the notification should still be actionable

  Scenario: Silent Notifications
    Given I have silent hours set from 10 PM to 7 AM
    And the current time is 11 PM
    When I receive a message
    Then the notification should be delivered silently
    And no sound should play
    And the screen should not light up
    And the notification should appear in notification center
    And the app badge should still update

  Scenario: Group Message Notifications
    Given I am in a group chat "Team Project"
    And I have group notifications enabled
    When "diana" posts in the group
    Then I should receive a notification
    And it should show "Team Project: Diana"
    And it should include the message preview
    And multiple group messages should be grouped
    And I should see a count of unread messages

  Scenario: Notification Actions
    Given I receive a message notification from "eve"
    When I long-press the notification
    Then I should see quick actions:
      | Reply  | Open text input    |
      | Mark Read | Clear notification |
      | Mute   | Disable notifications |
    When I select "Reply" and type "On my way"
    Then the reply should be sent
    And the notification should be dismissed

  Scenario: Notification Channels
    Given my device supports notification channels
    When I configure notification settings
    Then I should see separate channels for:
      | Messages     | High importance  |
      | Groups       | Default importance |
      | Mentions     | High importance  |
      | Files        | Low importance   |
      | System       | Min importance   |
    And I should be able to customize each channel

  Scenario: Web Push Notifications
    Given I am using the web app on Chrome
    When I allow browser notifications
    Then my browser should register for web push
    And I should receive notifications when the tab is closed
    And clicking the notification should focus the tab
    And notifications should work across devices

  Scenario: Notification Synchronization
    Given I have multiple devices registered
    When I read a message on device A
    Then the notification should be dismissed on device B
    And the notification should be dismissed on device C
    And all devices should sync read status
    And badge counts should update everywhere

  Scenario: Mention Notifications
    Given I am in a busy group chat
    And I have muted the group
    When someone mentions "@alice"
    Then I should still receive a notification
    And it should indicate I was mentioned
    And it should override mute settings
    And it should have high priority

  Scenario: Call Notifications
    Given "frank" is calling me
    When the call comes in
    Then I should receive a high-priority notification
    And it should show "Incoming call from Frank"
    And it should ring continuously
    And I should see Accept/Decline actions
    And it should work even in Do Not Disturb mode

  Scenario: File Share Notifications
    Given "grace" shares a file with me
    When the file is ready
    Then I should receive a notification
    And it should show "Grace shared a file"
    And it should include the filename
    And it should show file size
    And tapping should start download

  Scenario: Notification Queue
    Given I am offline for 2 hours
    When I come back online
    Then I should receive queued notifications
    And they should be in chronological order
    And old notifications should be grouped
    And I should not be overwhelmed with sounds
    And important notifications should be prioritized

  Scenario: Battery Optimization
    Given my device has battery optimization enabled
    When the app is in the background
    Then notifications should still be delivered
    And the app should use Firebase Cloud Messaging
    And battery usage should be minimal
    And high-priority notifications should wake the device

  Scenario: Notification Statistics
    Given I want to review my notification settings
    When I check notification stats
    Then I should see:
      | Total received today | 45 |
      | Average per hour    | 3  |
      | Most active sender  | Bob |
      | Quiet hours saved   | 12 |
    And I should be able to adjust settings based on stats

  Scenario: Rich Notifications
    Given "henry" sends me an image
    When I receive the notification
    Then I should see a thumbnail preview
    And I should be able to expand the notification
    And the full image should load
    And I should be able to reply with an emoji
    And I should be able to save the image

  Scenario: Location-based Notifications
    Given I have location sharing enabled
    When "ivan" shares his location
    Then I should receive a map notification
    And it should show a mini map preview
    And it should show distance from me
    And tapping should open full map

  Scenario: Notification Failure Recovery
    Given the notification service is temporarily down
    When it recovers
    Then missed notifications should be retrieved
    And they should be marked as delayed
    And critical notifications should be resent
    And users should be informed of the outage

  Scenario: E2E Encrypted Notifications
    Given notifications contain sensitive data
    When a notification is sent
    Then the payload should be encrypted
    And only the device should decrypt it
    And the server should not see content
    And notification service should not log content

  Scenario: Unsubscribe from Notifications
    Given I want to stop all notifications
    When I disable notifications in settings
    Then my device token should be removed
    And no more notifications should be sent
    And the change should sync across devices
    And I should be able to re-enable later