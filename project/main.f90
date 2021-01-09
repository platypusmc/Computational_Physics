program main
        use global
        use twoproton
        implicit none

        real :: S, a
        real, dimension(ncoord * 2, TotalWalkers) :: configuration
        real, dimension(:), allocatable :: Elocal, delphibeta, Edelphibeta
!        real, dimension(:), allocatable :: earray, evararray
        real, dimension(minimize_steps) :: betaarray, earray, evararray
        real :: beta, Energy, EnergyVar
        integer :: i, j, loc, Nos

        Nos = 5

        do i = 1, Nos + 1
                S = 1.3 + (i - 1) * 0.05
                a = 0.5
                betaarray(1) = 0.4
                call cala(S, a)

                write (*, '(A, A, A, A, A, A, A, A, A, A)'    &
                        , advance='no')  "Inter-Nuclear Seperation", TAB, "Variation Parameter β"       &
                        , TAB, "Mean Energy", TAB, "Variation", N_LINE

!                allocate(earray(minimize_steps))
!                allocate(evararray(minimize_steps))

                do j = 1, minimize_steps
                        allocate(Elocal(NTotal))
                        allocate(delphibeta(NTotal))
                        allocate(Edelphibeta(NTotal))

                        ! Generate position of electrons randomly
                        ! And calculating probabiliy and local energy of that configuration
                        call random_seed()
                        call genconfig(configuration)
                        call metropolis(configuration, S, a, betaarray(j), Elocal, delphibeta, Edelphibeta)

                        earray(j) = avg(Elocal(Nthermal: NTotal))
                        evararray(j) = var(Elocal(Nthermal: NTotal))
                        write (*        &
                                , '(*(g0.7), A, *(g0.7), A, *(g0.7), A, *(g0.7), A, *(g0.7), A)'    &
                                , advance='no')  S, TAB, betaarray(j), TAB, earray(j), TAB, evararray(j), N_LINE

                        if (j .ne. minimize_steps) betaarray(j + 1) = min_beta(betaarray(j), earray(j), delphibeta, Edelphibeta)

                        deallocate(Elocal)
                        deallocate(delphibeta)
                        deallocate(Edelphibeta)
                end do

                print *, "============================================================================================"

                loc = minloc(earray, dim=1)
                beta = betaarray(loc)
                Energy = earray(loc)
                EnergyVar = evararray(loc)

                write (*        &
                        , '(A, A, *(g0.7), A, *(g0.7), A, *(g0.7), A, *(g0.7), A, *(g0.7), A)', advance='no') &
                        "minimum", TAB, S, TAB, beta, TAB, Energy, TAB, EnergyVar, N_LINE

                print *, "============================================================================================"

!                deallocate(earray)
!                deallocate(evararray)

        end do

end program main
