// -----------------------------------------------------------------------------
// This file is part of utlib - A lightweight utility library
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the Mozilla Public License v2
//
// See https://mozilla.org/MPL/2.0 for license information
// -----------------------------------------------------------------------------

#pragma once

#include "utl/types/Exception.h"
#include "utl/types/Integers.h"
#include <atomic>
#include <functional>
#include <mutex>
#include <string>
#include <thread>

namespace utl {

/* How far along a long-running piece of work is.
 *
 * Written by the thread doing the work and read by whoever is watching it, so
 * everything here is atomic and none of it blocks: a worker calling advance()
 * on every chunk must not wait on a user interface, and a user interface
 * sampling it on every frame must not wait on the worker.
 *
 * 'total' may be zero, meaning the size of the job is not known yet. A watcher
 * shows that as an indeterminate bar rather than as nought percent.
 */
class Progress {

    std::atomic<i64> processed { 0 };
    std::atomic<i64> size { 0 };
    std::atomic<bool> aborted { false };

public:

    i64 done() const { return processed.load(std::memory_order_relaxed); }
    i64 total() const { return size.load(std::memory_order_relaxed); }

    // 0.0 ... 1.0, and 0.0 while the total is unknown
    double fraction() const {

        auto t = total();
        return t > 0 ? double(std::min(done(), t)) / double(t) : 0.0;
    }

    bool isKnown() const { return total() > 0; }

    void setTotal(i64 value) { size.store(value, std::memory_order_relaxed); }
    void setDone(i64 value) { processed.store(value, std::memory_order_relaxed); }
    void advance(i64 delta) { processed.fetch_add(delta, std::memory_order_relaxed); }

    /* Asks the worker to stop. Nothing is interrupted: the worker decides
     * where it is safe to give up, which it does by checking this between
     * chunks and throwing Aborted.
     */
    void cancel() { aborted.store(true, std::memory_order_relaxed); }
    bool cancelled() const { return aborted.load(std::memory_order_relaxed); }

    // Throws if cancellation has been requested. Call between chunks.
    void check() const { if (cancelled()) throw Aborted(); }

    void reset() { setDone(0); setTotal(0); aborted.store(false); }

    // Thrown by check() to unwind out of a cancelled task
    struct Aborted : Exception { };
};

/* A piece of work running on a thread of its own, with progress attached.
 *
 * The point is to keep something slow -- copying a disk image, saving a
 * workspace -- off the thread that draws the window, while still being able
 * to say how far it has got. Nothing here knows about any particular user
 * interface: a watcher samples state() and progress() whenever it likes, so
 * this works as well behind a Qt property as behind a Cocoa timer.
 *
 * One task runs one body at a time. start() on a task that is still running
 * throws rather than queueing, because two bodies sharing one Progress would
 * describe nothing.
 */
class Task {

public:

    enum class State { Idle, Running, Completed, Failed, Cancelled };

private:

    std::thread worker;
    Progress meter;

    std::atomic<State> current { State::Idle };

    // Set before the state leaves Running, read after it has; the mutex is
    // what makes that ordering something the compiler also agrees with.
    mutable std::mutex lock;
    std::string message;

public:

    Task() = default;
    ~Task() { cancel(); join(); }

    Task(const Task &) = delete;
    Task &operator=(const Task &) = delete;

    State state() const { return current.load(std::memory_order_acquire); }
    bool isRunning() const { return state() == State::Running; }

    Progress &progress() { return meter; }
    const Progress &progress() const { return meter; }

    // What went wrong, for a task that ended in State::Failed
    std::string error() const {

        std::lock_guard<std::mutex> guard(lock);
        return message;
    }

    /* Hands the body to a new thread and returns at once.
     *
     * The body is given the Progress to report through, and is expected to
     * call Progress::check() often enough that cancelling feels immediate.
     * Anything it throws ends the task in State::Failed, with what() kept for
     * error(); Progress::Aborted ends it in State::Cancelled instead.
     */
    void start(std::function<void(Progress &)> body) {

        if (isRunning()) throw Exception();

        join();
        meter.reset();
        {
            std::lock_guard<std::mutex> guard(lock);
            message.clear();
        }
        current.store(State::Running, std::memory_order_release);

        worker = std::thread([this, body = std::move(body)]() {

            auto finish = [this](State result, const std::string &text) {

                {
                    std::lock_guard<std::mutex> guard(lock);
                    message = text;
                }
                current.store(result, std::memory_order_release);
            };

            try {

                body(meter);
                finish(State::Completed, "");

            } catch (const Progress::Aborted &) {

                finish(State::Cancelled, "");

            } catch (const std::exception &e) {

                finish(State::Failed, e.what());

            } catch (...) {

                finish(State::Failed, "Unknown error");
            }
        });
    }

    // Asks the body to stop at its next opportunity. Does not wait for it.
    void cancel() { meter.cancel(); }

    // Waits for the worker to finish. Safe to call more than once.
    void join() { if (worker.joinable()) worker.join(); }
};

}
