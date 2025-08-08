# file_transfer.feature
# BDD scenarios for secure file transfer

Feature: Encrypted File Transfer
  As a user of the secure chat application
  I want to share files securely with other users
  So that I can exchange documents, images, and media safely

  Background:
    Given the file service is running
    And I am authenticated as "alice"
    And "bob" is another authenticated user
    And we have an encrypted channel established

  Scenario: Upload Small File
    Given I have a file "document.pdf" of size 2MB
    When I upload the file
    Then the file should be accepted
    And the file should be assigned a unique ID
    And the file should be stored encrypted
    And I should receive an upload confirmation
    And the file metadata should be saved
    And a shareable link should be generated

  Scenario: File Size Validation
    Given the maximum file size is 100MB
    When I try to upload a file of 150MB
    Then the upload should be rejected
    And I should receive an error "File too large"
    And no storage should be consumed
    When I upload a file of 50MB
    Then the upload should succeed

  Scenario: File Type Validation
    Given allowed file types are [pdf, jpg, png, doc, zip]
    When I upload "script.exe"
    Then the upload should be rejected
    And I should receive an error "File type not allowed"
    When I upload "photo.jpg"
    Then the upload should be accepted

  Scenario: File Encryption Before Storage
    Given I upload "sensitive.pdf"
    When the file is processed
    Then it should be encrypted with AES-256-GCM
    And a unique file key should be generated
    And the file key should be encrypted with recipient's public key
    And the encrypted file should be stored
    And the original file should be deleted from temporary storage
    And encryption metadata should be saved

  Scenario: Send File to User
    Given I have uploaded "report.pdf"
    When I send the file to "bob"
    Then the file key should be encrypted for "bob"
    And a file message should be created containing:
      | file_id     | Unique identifier |
      | file_name   | report.pdf        |
      | file_size   | 2048000           |
      | mime_type   | application/pdf   |
      | encrypted_key | For bob          |
    And the message should be sent via WebSocket
    And "bob" should receive the file notification

  Scenario: Download Shared File
    Given "alice" has shared "photo.jpg" with me
    And I have received the encrypted file key
    When I download the file
    Then I should decrypt the file key with my private key
    And I should retrieve the encrypted file
    And I should decrypt the file with the file key
    And I should receive the original "photo.jpg"
    And the file integrity should be verified

  Scenario: Thumbnail Generation for Images
    Given I upload an image "vacation.jpg"
    When the upload completes
    Then a thumbnail should be generated
    And the thumbnail should be 200x200 pixels
    And the thumbnail should be encrypted
    And the thumbnail should be stored separately
    And preview should be available without full download

  Scenario: Resume Interrupted Upload
    Given I am uploading "large_video.mp4" of 50MB
    When the connection interrupts at 60% progress
    And I reconnect within 5 minutes
    Then I should be able to resume from 60%
    And the upload should continue from last chunk
    And the final file should be complete
    And integrity check should pass

  Scenario: Multi-part Upload for Large Files
    Given I upload "archive.zip" of 80MB
    When the upload begins
    Then the file should be split into 5MB chunks
    And each chunk should be uploaded separately
    And each chunk should be encrypted
    And chunks should be reassembled on server
    And the complete file should be verified

  Scenario: File Expiration
    Given I share a file with 24-hour expiration
    When I upload "temporary.pdf"
    Then expiration time should be set
    And the file should be accessible for 24 hours
    When 24 hours pass
    Then the file should be automatically deleted
    And download attempts should fail
    And storage should be freed

  Scenario: Batch File Upload
    Given I select multiple files:
      | file1.pdf | 2MB |
      | file2.jpg | 3MB |
      | file3.doc | 1MB |
    When I upload them together
    Then all files should be processed
    And each should get unique ID
    And progress should show for each file
    And all should be encrypted separately
    And batch completion should be notified

  Scenario: File Access Control
    Given I upload "private.pdf" with restrictions
    When I set access to "bob" and "charlie" only
    Then only specified users should access the file
    And "diana" should not be able to download
    And access attempts should be logged
    And I should be able to revoke access

  Scenario: Virus Scanning
    Given virus scanning is enabled
    When I upload "document.pdf"
    Then the file should be scanned for malware
    And if clean, upload should proceed
    And if infected, file should be rejected
    And I should be notified of scan results
    And infected files should be quarantined

  Scenario: File Search
    Given I have uploaded 50 files
    When I search for "report"
    Then I should see files matching "report" in name
    And results should include metadata
    And results should be paginated
    And I should be able to filter by type
    And I should be able to sort by date/size

  Scenario: Storage Quota Management
    Given I have 1GB storage quota
    And I have used 900MB
    When I try to upload 200MB file
    Then I should receive quota warning
    And upload should be rejected
    When I delete old files freeing 300MB
    Then I should be able to upload the file

  Scenario: File Versioning
    Given I have uploaded "document.pdf" version 1
    When I upload updated "document.pdf"
    Then it should be saved as version 2
    And previous version should be retained
    And I should be able to access version history
    And I should be able to restore old versions
    And storage should count all versions

  Scenario: Shared Folder
    Given I create a shared folder "Project Files"
    When I add "bob" and "charlie" as members
    Then they should access the folder
    And files uploaded to folder should be visible to all
    And members should be able to upload files
    And folder permissions should be manageable

  Scenario: File Comments
    Given "bob" has shared "design.png" with me
    When I add a comment "Looks good!"
    Then the comment should be attached to the file
    And "bob" should see my comment
    And comments should be timestamped
    And comment history should be maintained

  Scenario: Download Statistics
    Given I have shared "report.pdf" with my team
    When team members download the file
    Then I should see download count
    And I should see who downloaded
    And I should see download timestamps
    And I should see download locations

  Scenario: Encrypted File Links
    Given I want to share "public.pdf" via link
    When I generate a shareable link
    Then the link should include encrypted access token
    And the link should work without authentication
    And I should be able to set link expiration
    And I should be able to revoke the link
    And link access should be tracked