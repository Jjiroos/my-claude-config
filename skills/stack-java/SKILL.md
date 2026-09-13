---
name: stack-java
description: Conventions Java 17 de mes projets (Maven, JUnit 5, projets javac sans outil de build). Charger avant de compiler, lancer des tests ou utiliser une fonctionnalité récente du langage.
paths:
  - "**/*.java"
  - "**/pom.xml"
---

# Stack Java 17

## Build

- Avec `pom.xml` : `mvn -q test` ; un seul test : `mvn -q -Dtest='Classe#methode' test` ; compilation seule : `mvn -q test-compile`.
- Le premier `mvn` d'une machine télécharge les dépendances : borne-le (`timeout 300`) et passe-le en tâche de fond s'il s'éternise.
- Sans `pom.xml` : `javac -d out $(find src -name '*.java')`, puis `java -cp out <ClassePrincipale>`.

## Périmètre du langage : Java 17 sans preview

- Standard en 17 : records, classes `sealed`, text blocks, expressions `switch`, pattern matching de `instanceof`.
- Le pattern matching dans `switch` est en preview en 17 (standard en 21), et les record patterns arrivent après 17 : n'écris ces formes que si le projet active `--enable-preview` et cible une version qui les porte.
- Ce périmètre est aussi celui de la certification 1Z0-829.

## Tests

JUnit 5 (Jupiter) via surefire : assertions `org.junit.jupiter.api.Assertions`, tests paramétrés avec `@ParameterizedTest`.
