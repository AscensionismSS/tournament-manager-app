import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tournament_creator_front/core/shared_widgets/shared_widgets.dart';
import 'package:tournament_creator_front/core/storage/token_storage.dart';
import 'package:tournament_creator_front/core/theme/theme.dart';
import 'package:tournament_creator_front/features/admin/invitations/controllers/invitations_controller.dart';
import 'package:tournament_creator_front/features/admin/invitations/presentation/create_invitation_dialog.dart';
import 'package:tournament_creator_front/features/admin/members/presentation/widgets/admin_member_mobile_card.dart';
import 'package:tournament_creator_front/features/admin/members/presentation/widgets/admin_members_table.dart';
import 'package:tournament_creator_front/features/auth/models/login_response.dart';
import 'package:tournament_creator_front/features/members/models/member_dto.dart';
import 'package:tournament_creator_front/features/shell/presentation/user_profile_menu.dart';

LoginResponse _buildProfile({
  String role = 'SuperAdmin',
  bool isRootOwner = false,
}) {
  return LoginResponse(
    userId: 'user-1',
    email: 'admin@tsurus.gg',
    displayName: 'Admin Teste',
    role: role,
    token: 'jwt-token',
    isSteamLinked: true,
    isRootOwner: isRootOwner,
  );
}

MemberDto _buildMember({
  required String userId,
  required String displayName,
  bool isRootOwner = false,
  bool isActive = true,
  String role = 'SuperAdmin',
}) {
  return MemberDto(
    userId: userId,
    displayName: displayName,
    role: role,
    isActive: isActive,
    isRootOwner: isRootOwner,
    email: '$userId@tsurus.gg',
  );
}

void main() {
  tearDown(() {
    TokenStorage.profileNotifier.value = null;
  });

  group('LoginResponse & MemberDto isRootOwner parsing', () {
    test('LoginResponse parses camelCase, PascalCase, defaults to false, and preserves in toJson/copyWith', () {
      final defaultParsed = LoginResponse.fromJson({
        'userId': 'u1',
        'email': 'player@tsurus.gg',
        'displayName': 'Player',
        'role': 'Player',
        'token': 'abc',
      });
      expect(defaultParsed.isRootOwner, isFalse);

      final camelParsed = LoginResponse.fromJson({
        'userId': 'u2',
        'email': 'root@tsurus.gg',
        'displayName': 'Root',
        'role': 'SuperAdmin',
        'token': 'abc',
        'isRootOwner': true,
      });
      expect(camelParsed.isRootOwner, isTrue);

      final pascalParsed = LoginResponse.fromJson({
        'data': {
          'userId': 'u3',
          'email': 'root2@tsurus.gg',
          'displayName': 'Root2',
          'role': 'SuperAdmin',
          'token': 'abc',
          'IsRootOwner': true,
        },
      });
      expect(pascalParsed.isRootOwner, isTrue);

      final roundTripJson =
          jsonDecode(jsonEncode(camelParsed.toJson())) as Map<String, dynamic>;
      final rehydrated = LoginResponse.fromJson(roundTripJson);
      expect(rehydrated.isRootOwner, isTrue);

      final downgraded = camelParsed.copyWith(isRootOwner: false);
      expect(downgraded.isRootOwner, isFalse);
      final unchangedCopy = camelParsed.copyWith(displayName: 'Root Renamed');
      expect(unchangedCopy.isRootOwner, isTrue);
    });

    test('MemberDto parses isRootOwner in camelCase, PascalCase and defaults to false', () {
      final defaultMember = MemberDto.fromJson({
        'userId': 'm1',
        'displayName': 'Comum',
        'role': 'User',
      });
      expect(defaultMember.isRootOwner, isFalse);

      final camelMember = MemberDto.fromJson({
        'userId': 'm2',
        'displayName': 'Dono',
        'role': 'SuperAdmin',
        'isRootOwner': true,
      });
      expect(camelMember.isRootOwner, isTrue);

      final pascalMember = MemberDto.fromJson({
        'userId': 'm3',
        'displayName': 'Dono2',
        'role': 'SuperAdmin',
        'IsRootOwner': true,
      });
      expect(pascalMember.isRootOwner, isTrue);
    });
  });

  group('UserProfileMenu Segurança do Sistema visibility', () {
    testWidgets('hides Segurança do Sistema for non-root SuperAdmin', (tester) async {
      TokenStorage.profileNotifier.value =
          _buildProfile(role: 'SuperAdmin', isRootOwner: false);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            appBar: AppBar(
              actions: const [UserProfileMenu()],
            ),
          ),
        ),
      );

      await tester.tap(find.byType(UserProfileMenu));
      await tester.pumpAndSettle();

      expect(find.text('Preferências Gerais'), findsOneWidget);
      expect(find.text('Segurança do Sistema'), findsNothing);
    });

    testWidgets('shows Segurança do Sistema for Root Owner', (tester) async {
      TokenStorage.profileNotifier.value =
          _buildProfile(role: 'SuperAdmin', isRootOwner: true);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            appBar: AppBar(
              actions: const [UserProfileMenu()],
            ),
          ),
        ),
      );

      await tester.tap(find.byType(UserProfileMenu));
      await tester.pumpAndSettle();

      expect(find.text('Preferências Gerais'), findsOneWidget);
      expect(find.text('Segurança do Sistema'), findsOneWidget);
    });
  });

  group('CreateInvitationDialog SuperAdmin lock vs Admin Torneio', () {
    testWidgets('non-root SuperAdmin can select Admin Torneio but cannot select SuperAdmin',
        (tester) async {
      TokenStorage.profileNotifier.value =
          _buildProfile(role: 'SuperAdmin', isRootOwner: false);
      final controller = InvitationsController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: CreateInvitationDialog(controller: controller),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Admin Torneio'));
      await tester.pump();
      expect(find.textContaining('Admin de Torneio:'), findsOneWidget);

      await tester.tap(find.text('SuperAdmin'));
      await tester.pump();
      expect(find.textContaining('Super Administrador:'), findsNothing);
      expect(find.textContaining('Admin de Torneio:'), findsOneWidget);
    });

    testWidgets('Root Owner can select both Admin Torneio and SuperAdmin',
        (tester) async {
      TokenStorage.profileNotifier.value =
          _buildProfile(role: 'SuperAdmin', isRootOwner: true);
      final controller = InvitationsController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: CreateInvitationDialog(controller: controller),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('SuperAdmin'));
      await tester.pump();
      expect(find.textContaining('Super Administrador:'), findsOneWidget);
    });
  });

  group('Admin Members root owner protection UI', () {
    testWidgets('AdminMembersTable hides moderation lock button for root owner and keeps it for others',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      MemberDto? toggledMember;
      final rootMember = _buildMember(
        userId: 'root-1',
        displayName: 'Dono Raiz',
        isRootOwner: true,
      );
      final normalAdmin = _buildMember(
        userId: 'admin-2',
        displayName: 'Admin Normal',
        isRootOwner: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: AdminMembersTable(
              members: [rootMember, normalAdmin],
              onToggleStatus: (m) => toggledMember = m,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byIcon(Icons.verified_user_rounded), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (w) => w is Tooltip && w.message == 'Proprietário Raiz protegido',
        ),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.lock_rounded), findsOneWidget);

      await tester.tap(find.byIcon(Icons.lock_rounded));
      await tester.pump();
      expect(toggledMember?.userId, 'admin-2');
    });

    testWidgets('AdminMemberMobileCard replaces Bloquear Login with protected badge for root owner',
        (tester) async {
      MemberDto? toggledMember;
      final rootMember = _buildMember(
        userId: 'root-1',
        displayName: 'Dono Raiz',
        isRootOwner: true,
      );
      final normalMember = _buildMember(
        userId: 'user-2',
        displayName: 'Jogador Comum',
        isRootOwner: false,
        role: 'User',
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: SingleChildScrollView(
              child: Column(
                children: [
                  AdminMemberMobileCard(
                    member: rootMember,
                    onToggleStatus: (m) => toggledMember = m,
                  ),
                  AdminMemberMobileCard(
                    member: normalMember,
                    onToggleStatus: (m) => toggledMember = m,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byIcon(Icons.verified_user_rounded), findsOneWidget);
      expect(find.text('PROPRIETÁRIO RAIZ PROTEGIDO'), findsOneWidget);
      expect(find.byType(AppButton), findsOneWidget);
      expect(find.text('BLOQUEAR LOGIN'), findsOneWidget);

      await tester.tap(find.byType(AppButton));
      await tester.pump();
      expect(toggledMember?.userId, 'user-2');
    });
  });
}
