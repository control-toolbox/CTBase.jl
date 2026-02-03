module TestUnauthorizedCallExamples

using Test
using CTBase

"""
Demo module for realistic UnauthorizedCall examples.
"""
module DemoSecuritySystem
    using CTBase
    
    """
    User permission levels.
    """
    @enum PermissionLevel GUEST USER ADMIN SUPERADMIN
    
    """
    User struct with permissions.
    """
    struct User
        name::String
        level::PermissionLevel
        is_active::Bool
    end
    
    """
    Check if user has required permission level.
    """
    function check_permission(user::User, required_level::PermissionLevel, action::String)
        if !user.is_active
            throw(CTBase.Exceptions.UnauthorizedCall(
                "user account is not active",
                user=user.name,
                reason="Account disabled or suspended",
                suggestion="Contact administrator to reactivate account",
                context="security check for action: $action"
            ))
        end
        
        if user.level < required_level
            throw(CTBase.Exceptions.UnauthorizedCall(
                "insufficient permissions for action",
                user=user.name,
                reason="User level: $(user.level), Required: $(required_level)",
                suggestion="Request elevated permissions from administrator",
                context="permission validation for action: $action"
            ))
        end
        
        return true
    end
    
    """
    Delete system data (requires ADMIN).
    """
    function delete_system_data(user::User, data_id::String)
        check_permission(user, ADMIN, "delete system data")
        println("🗑️  Data $data_id deleted by $(user.name)")
        return true
    end
    
    """
    Access system logs (requires USER).
    """
    function access_system_logs(user::User)
        check_permission(user, USER, "access system logs")
        println("📋 Logs accessed by $(user.name)")
        return ["log1", "log2", "log3"]
    end
    
    """
    Modify system configuration (requires SUPERADMIN).
    """
    function modify_system_config(user::User, config::Dict)
        check_permission(user, SUPERADMIN, "modify system configuration")
        println("⚙️  Configuration modified by $(user.name)")
        return true
    end
end

function test_unauthorized_call_examples()
    println("🔍 UnauthorizedCall Examples")
    println("="^50)
    
    # Create test users
    guest_user = DemoSecuritySystem.User("alice", DemoSecuritySystem.GUEST, true)
    regular_user = DemoSecuritySystem.User("bob", DemoSecuritySystem.USER, true)
    admin_user = DemoSecuritySystem.User("charlie", DemoSecuritySystem.ADMIN, true)
    inactive_user = DemoSecuritySystem.User("dave", DemoSecuritySystem.USER, false)
    
    # Example 1: Inactive user trying to access
    println("\n🚫 Example 1: Inactive User Access Attempt")
    println("─"^40)
    
    try
        DemoSecuritySystem.access_system_logs(inactive_user)
    catch e
        showerror(stdout, e)
        println()
    end
    
    # Example 2: Guest trying to access admin functions
    println("\n👤 Example 2: Guest User Accessing Admin Functions")
    println("─"^40)
    
    try
        DemoSecuritySystem.delete_system_data(guest_user, "data123")
    catch e
        showerror(stdout, e)
        println()
    end
    
    # Example 3: Regular user trying superadmin functions
    println("\n🔐 Example 3: Regular User Accessing Superadmin Functions")
    println("─"^40)
    
    try
        DemoSecuritySystem.modify_system_config(regular_user, Dict("setting" => "value"))
    catch e
        showerror(stdout, e)
        println()
    end
    
    # Example 4: Successful access (for comparison)
    println("\n✅ Example 4: Successful Authorized Access")
    println("─"^40)
    
    try
        DemoSecuritySystem.access_system_logs(regular_user)
        println("📋 Logs accessed by $(regular_user.name)")
        println("✅ Access successful")
    catch e
        showerror(stdout, e)
        println()
    end
    
    return nothing
end

end # module

# Export for external use
test_unauthorized_call_examples() = TestUnauthorizedCallExamples.test_unauthorized_call_examples()
