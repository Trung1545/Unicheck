package com.unicheck.security;

import com.unicheck.model.entity.User;
import com.unicheck.model.enums.UserStatus;
import lombok.Getter;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.userdetails.UserDetails;

import java.util.Collection;
import java.util.HashSet;
import java.util.Set;

@Getter
public class UserPrincipal implements UserDetails {

    private final User user;
    private final Collection<? extends GrantedAuthority> authorities;

    public UserPrincipal(User user) {
        this.user = user;
        Set<SimpleGrantedAuthority> auths = new HashSet<>();
        if (user.getRole() != null) {
            String roleName = user.getRole().name();
            // Both ROLE_PREFIX and bare role name for maximum compatibility with hasRole and hasAuthority
            auths.add(new SimpleGrantedAuthority("ROLE_" + roleName));
            auths.add(new SimpleGrantedAuthority(roleName));
        }
        if (user.getPermissions() != null) {
            user.getPermissions().forEach(p -> {
                if (p.getPermission() != null && !p.getPermission().isBlank()) {
                    auths.add(new SimpleGrantedAuthority(p.getPermission()));
                }
            });
        }
        this.authorities = auths;
    }

    public Long getId() {
        return user.getId();
    }

    public String getCode() {
        return user.getCode();
    }

    public String getEmail() {
        return user.getEmail();
    }

    @Override
    public Collection<? extends GrantedAuthority> getAuthorities() {
        return authorities;
    }

    @Override
    public String getPassword() {
        return user.getPassword();
    }

    @Override
    public String getUsername() {
        return user.getUsername();
    }

    @Override
    public boolean isAccountNonExpired() {
        return true;
    }

    @Override
    public boolean isAccountNonLocked() {
        return user.getStatus() != UserStatus.BLOCKED;
    }

    @Override
    public boolean isCredentialsNonExpired() {
        return true;
    }

    @Override
    public boolean isEnabled() {
        return user.getStatus() == UserStatus.ACTIVE;
    }
}
