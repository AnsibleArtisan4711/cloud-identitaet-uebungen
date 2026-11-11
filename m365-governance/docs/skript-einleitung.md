# Einleitung

> **Hinweis:** Teil des Skripts „M365 Governance – Lernmodule nach Lehrplan“, aus der LaTeX-Quelle in Markdown umgewandelt. Die Kapitel zu den Modulen stehen als `skript.md` in den Modulordnern.

Dieses Skript führt Schritt für Schritt durch die Governance von Microsoft 365. Es folgt der Gliederung des Lehrplans „Lehrplan - M365 Governance“ (Blätter „Lehrplan in Modulen“ und „Lehrplan in Details“). Jede Lerneinheit des Detailblatts hat einen eigenen Abschnitt. Jeder Abschnitt erklärt zuerst in zusammenhängender Prosa, was ein Thema ist, wozu man es braucht und wie es funktioniert, zeigt dann ein vollständiges Beispiel mit Erläuterung, benennt typische Fehler mit einem Gegenbeispiel und schließt mit dem Praxisbezug. Am Ende jedes Moduls stehen Übungsaufgaben mit steigender Schwierigkeit, deren Lösungen mit Erklärung getrennt dahinter folgen.

> **Wichtig: Quellenbasis und Stand der Beispiele**
>
> **Quellenbasis.** Im Projektwissen lagen keine Kursunterlagen vor. Der Inhalt beruht daher auf dem Lehrplan, auf der Recherche in der öffentlichen Microsoft-Dokumentation (Microsoft Learn) und auf allgemeinem Fachwissen. Stellen, die aus der Nachrecherche stammen, stehen in grünen Kästen mit dem Titel „Ergänzung aus der Nachrecherche“.
>
> **Code nicht ausgeführt.** Alle PowerShell-Beispiele folgen den Cmdlets und Mustern der Microsoft-Dokumentation. Sie wurden *nicht* gegen einen echten Tenant ausgeführt. Bevor Sie ein Skript produktiv einsetzen, testen Sie es in einem Testtenant mit Testdaten. Cmdlets, Parameter und Berechtigungen ändern sich; die Dokumentation von Microsoft ist maßgeblich.
>
> **Keine Rechtsberatung.** Hinweise zu Datenschutz (DSGVO), Aufbewahrung und anderen rechtlichen Themen sind fachliche Orientierung und keine Rechtsberatung. Rechtliche Bewertungen gehören in die Hand der Datenschutzbeauftragten oder einer Rechtsberatung.

## Zu den Stundenangaben

Der Lehrplan nennt im Blatt „Lehrplan in Modulen“ und im Blatt „Lehrplan in Details“ unterschiedliche Stundenzahlen. Die Summe der Details liegt in mehreren Modulen unter der Modulangabe. Die Module in diesem Skript nennen deshalb beide Werte in ihrer Kopftabelle. Als Richtwert für den Umfang wurde jeweils der höhere Wert (Modulblatt) verwendet, mindestens eine Seite je geplanter Unterrichtsstunde.

## Voraussetzungen und Schreibweisen

Sie brauchen für die Beispiele PowerShell 7, das Microsoft-Graph-PowerShell-Modul, das SharePoint-Online-Verwaltungsmodul sowie ein Konto mit passenden Berechtigungen in einem Testtenant. Befehle und Dateinamen sind in Schreibmaschinenschrift gesetzt. Platzhalter in spitzen Klammern ersetzen Sie durch Ihre eigenen Werte. In den Beispielen wurden Umlaute in Code und Kommentaren bewusst als „ae“, „oe“, „ue“ geschrieben, damit die Skripte in jeder Umgebung ohne Zeichensatzprobleme laufen.
