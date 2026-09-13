---
name: stack-ue5-wsl
description: Développer un projet Unreal Engine 5 C++ depuis WSL — build par cmd.exe, éditeur et serveur MCP Unreal, sauvegarde et vérification des assets. Charger avant de compiler, lancer ou fermer l'éditeur, ou agir via les outils MCP Unreal.
paths:
  - "**/*.uproject"
  - "**/Source/**/*.{h,cpp,cs}"
  - "**/Config/*.ini"
---

# UE5 C++ depuis WSL

Le moteur et l'éditeur tournent sous Windows ; tout se pilote depuis WSL par l'interop (`cmd.exe`, `taskkill.exe`, `netstat.exe`). Mets les chemins Windows entre quotes pour garder les `\`.

## Compiler le module éditeur

```bash
cmd.exe /c '<Moteur>\Engine\Build\BatchFiles\Build.bat <Projet>Editor Win64 Development <Dossier>\<Projet>.uproject -WaitMutex -NoHotReload'
```

- Éditeur fermé, ou Live Coding désactivé : sinon UHT passe mais la compilation C++ échoue (`Unable to build while Live Coding is active`).
- UBT découvre seul les nouveaux `.h`/`.cpp` du module ; `GenerateProjectFiles` ne sert qu'à l'IDE.

## Cycle éditeur + MCP

1. **Lancer** en forçant le serveur MCP, dont l'auto-start n'est pas fiable :
   `cmd.exe /c start "" "<Moteur>\Engine\Binaries\Win64\UnrealEditor.exe" "<Dossier>\<Projet>.uproject" -ExecCmds="ModelContextProtocol.StartServer" &`
   puis attends `netstat.exe -an | grep "127.0.0.1:8000.*LISTENING"` (60 à 120 s).
2. **Réseau** : le serveur écoute sur `127.0.0.1` ; WSL doit être en `networkingMode=mirrored` (`.wslconfig` côté Windows).
3. **Connexion** : le client MCP ne se connecte qu'au démarrage de la session Claude. Éditeur éteint à ce moment-là : parle au serveur en JSON-RPC (`POST http://127.0.0.1:8000/mcp`, `initialize` → en-tête `Mcp-Session-Id`, `notifications/initialized`, puis `tools/call` sur `call_tool`).
4. **Sauver** : ce que le MCP écrit vit en mémoire. Sauve après chaque lot (`save_assets`) et vérifie le `.uasset` sur disque côté WSL (`ls Content/…`) : un `true` renvoyé ne prouve pas l'écriture.
5. **Voir** : `CaptureEditorImage`, décode le base64 en PNG dans le scratchpad, puis lis l'image.
6. **Fermer** avant un build C++ : sauve, puis `taskkill.exe /IM UnrealEditor.exe /F /T` (sans `/F`, l'éditeur reste bloqué sur une confirmation).

## Assets

Si `.gitattributes` suit `Content/` en LFS, vérifie `git lfs status` avant de committer des `.uasset`/`.umap`.

Les pièges propres à un projet (toolsets disponibles, classes, conventions de nommage) vivent dans son `CLAUDE.md` et sa mémoire.
