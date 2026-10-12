package com.unicheck.repository;

import com.unicheck.model.entity.User;
import com.unicheck.model.enums.Role;
import com.unicheck.model.enums.UserStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface UserRepository extends JpaRepository<User, Long> {

    Optional<User> findByCode(String code);

    Optional<User> findByUsername(String username);

    Optional<User> findByEmail(String email);

    boolean existsByCode(String code);

    boolean existsByUsername(String username);

    boolean existsByEmail(String email);

    List<User> findByStatus(UserStatus status);

    List<User> findByRole(Role role);
}
