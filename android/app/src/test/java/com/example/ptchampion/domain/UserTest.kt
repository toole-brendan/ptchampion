package com.example.ptchampion.domain

import org.junit.Test
import org.junit.Assert.*
import java.util.Date

class UserTest {
    
    @Test
    fun `test user initialization`() {
        // Create a user
        val user = User(
            id = 1,
            username = "testuser",
            email = "test@example.com",
            fullName = "Test User",
            createdAt = Date(),
            profileImageUrl = null
        )
        
        // Verify fields are set correctly
        assertEquals(1, user.id)
        assertEquals("testuser", user.username)
        assertEquals("test@example.com", user.email)
        assertEquals("Test User", user.fullName)
        assertNull(user.profileImageUrl)
    }
    
    @Test
    fun `test user equality is based on id`() {
        val user1 = User(
            id = 1,
            username = "testuser",
            email = "test@example.com",
            fullName = "Test User",
            createdAt = Date(),
            profileImageUrl = null
        )
        
        val user2 = User(
            id = 1,
            username = "different",
            email = "different@example.com",
            fullName = "Different User",
            createdAt = Date(),
            profileImageUrl = null
        )
        
        val user3 = User(
            id = 2,
            username = "testuser",
            email = "test@example.com",
            fullName = "Test User",
            createdAt = Date(),
            profileImageUrl = null
        )
        
        // Users with same ID should be equal
        assertEquals(user1, user2)
        // Users with different IDs should not be equal
        assertNotEquals(user1, user3)
    }
    
    @Test
    fun `test displayName returns fullName when available`() {
        val user = User(
            id = 1,
            username = "testuser",
            email = "test@example.com",
            fullName = "Test User",
            createdAt = Date(),
            profileImageUrl = null
        )
        
        assertEquals("Test User", user.displayName)
    }
    
    @Test
    fun `test displayName returns username when fullName is empty`() {
        val user = User(
            id = 1,
            username = "testuser",
            email = "test@example.com",
            fullName = "",
            createdAt = Date(),
            profileImageUrl = null
        )
        
        assertEquals("testuser", user.displayName)
    }
    
    @Test
    fun `test hasProfileImage returns true when profileImageUrl is not null`() {
        val user = User(
            id = 1,
            username = "testuser",
            email = "test@example.com",
            fullName = "Test User",
            createdAt = Date(),
            profileImageUrl = "https://example.com/image.jpg"
        )
        
        assertTrue(user.hasProfileImage)
    }
    
    @Test
    fun `test hasProfileImage returns false when profileImageUrl is null`() {
        val user = User(
            id = 1,
            username = "testuser",
            email = "test@example.com",
            fullName = "Test User",
            createdAt = Date(),
            profileImageUrl = null
        )
        
        assertFalse(user.hasProfileImage)
    }
    
    @Test
    fun `test getInitials returns first and last name initials`() {
        val user = User(
            id = 1,
            username = "testuser",
            email = "test@example.com",
            fullName = "Test User",
            createdAt = Date(),
            profileImageUrl = null
        )
        
        assertEquals("TU", user.getInitials())
    }
    
    @Test
    fun `test getInitials returns single letter for single name`() {
        val user = User(
            id = 1,
            username = "testuser",
            email = "test@example.com",
            fullName = "Test",
            createdAt = Date(),
            profileImageUrl = null
        )
        
        assertEquals("T", user.getInitials())
    }
    
    @Test
    fun `test getInitials uses username when fullName is empty`() {
        val user = User(
            id = 1,
            username = "testuser",
            email = "test@example.com",
            fullName = "",
            createdAt = Date(),
            profileImageUrl = null
        )
        
        assertEquals("T", user.getInitials())
    }
} 