// -----------------------------------------------------------------------------
// This file is part of Silicium UI
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

#pragma once

#include "Controller.h"
#include "SVMFile.h"
#include <QObject>
#include <QStringList>

using retro::vault::SVMFile;

class OnboardingController : public Controller {

    Q_OBJECT

    // Navigation
    QString m_page = "welcome";

    // Configuration
    QString m_platform = "c64";
    QString m_name = "Untitled";
    QString m_modelC64 = "c64";
    QString m_romC64 = "mega";
    QString m_modelAmiga = "a500";
    QString m_romAmiga = "aros";

    QStringList m_pageList;

  public:

    // Navigation
    Q_PROPERTY(int pageCount READ pageCount NOTIFY pageChanged)
    Q_PROPERTY(QString page READ page WRITE setPage NOTIFY pageChanged)
    Q_PROPERTY(int index READ index WRITE setIndex NOTIFY pageChanged)
    Q_PROPERTY(bool hasPrevPage READ hasPrevPage NOTIFY pageChanged)
    Q_PROPERTY(bool hasNextPage READ hasNextPage NOTIFY pageChanged)

    // Configuration
    Q_PROPERTY(QString name READ name WRITE setName NOTIFY nameChanged)
    Q_PROPERTY(QString platform READ platform WRITE setPlatform NOTIFY platformChanged)
    Q_PROPERTY(QUrl platformIcon READ platformIcon NOTIFY platformChanged)
    Q_PROPERTY(QString modelC64 READ modelC64 WRITE setModelC64 NOTIFY modelC64Changed)
    Q_PROPERTY(QString romC64 READ romC64 WRITE setRomC64 NOTIFY romC64Changed)
    Q_PROPERTY(QString modelAmiga READ modelAmiga WRITE setModelAmiga NOTIFY modelAmigaChanged)
    Q_PROPERTY(QString romAmiga READ romAmiga WRITE setRomAmiga NOTIFY romAmigaChanged)

public:

    // Functions
    Q_INVOKABLE QString nextPage() const;
    Q_INVOKABLE QString prevPage() const;
    Q_INVOKABLE void next();
    Q_INVOKABLE void prev();

    // Creates a new virtual machine
    Q_INVOKABLE QUrl create(const QString &path);
    Q_INVOKABLE QUrl create(const QUrl &path);
    QUrl create(const fs::path &path);

  private:

    void createC64Workspace(SVMFile &svm);
    void createAmigaWorkspace(SVMFile &svm);

    // Creates the workspace folder of a freshly made SVM and returns its path
    static fs::path prepareWorkspaceFolder(SVMFile &svm);
    void createC64ConfigScript(SVMFile &svm, const fs::path &scriptFile);
    void createAmigaConfigScript(SVMFile &svm, const fs::path &scriptFile);

  public:

    explicit OnboardingController(QObject *parent = nullptr);
    static OnboardingController *instance();

    QString page() const { return m_page; }
    void setPage(const QString &value);

    int index() const;
    void setIndex(int value);

    int pageCount() const { return m_pageList.count(); }

    bool hasNextPage() const;
    bool hasPrevPage() const;
    QUrl platformIcon() const;

    QString name() const { return m_name; }
    void setName(const QString &value);

    QString platform() const { return m_platform; }
    void setPlatform(const QString &value);

    QString modelC64() const { return m_modelC64; }
    void setModelC64(const QString &value);

    QString modelAmiga() const { return m_modelAmiga; }
    void setModelAmiga(const QString &value);

    QString romC64() const { return m_romC64; }
    void setRomC64(const QString &value);

    QString romAmiga() const { return m_romAmiga; }
    void setRomAmiga(const QString &value);

  signals:
    void pageChanged();
    void pageCountChanged();
    void indexChanged();

    void nameChanged();
    void platformChanged();
    void modelC64Changed();
    void romC64Changed();
    void modelAmigaChanged();
    void romAmigaChanged();

  private:

    void buildPageList();
};