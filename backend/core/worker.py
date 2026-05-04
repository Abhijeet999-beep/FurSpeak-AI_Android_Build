import asyncio
import logging

logger = logging.getLogger("GPU-Worker")

job_queue = asyncio.Queue()

async def gpu_worker():
    """ Runs continuously in the background separating GPU loads across bounded Queues perfectly. """
    logger.info("Initializing Single-GPU Worker Loop...")
    while True:
        try:
            job = await job_queue.get()
            job_id, future, func, args, kwargs = job
            
            # If the API route already timed out and cancelled the future, skip inference completely rescuing GPU overload natively!
            if future.cancelled():
                logger.debug(f"[Worker] Skipped cancelled job {job_id}")
                job_queue.task_done()
                continue
                
            logger.info(f"[Worker] Starting execution for job {job_id}")
            
            try:
                # YOLO execution is deeply blocking processing structures. Offloading sequentially explicitly handles serial GPU boundaries safely.
                result = await asyncio.to_thread(func, *args, **kwargs)
                if not future.cancelled() and not future.done():
                    future.set_result(result)
            except Exception as e:
                logger.error(f"[Worker] Execution failed for {job_id}: {e}")
                if not future.cancelled() and not future.done():
                    future.set_exception(e)
            finally:
                job_queue.task_done()
        except asyncio.CancelledError:
            logger.warning("GPU Worker task shutdown requested.")
            break
        except Exception as e:
            logger.error(f"[Worker] Fatal Loop Error: {e}")
